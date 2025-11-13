# Example: Multi-Tenant QuickBooks Integration
#
# This example shows how to use different QuickBooks credentials per tenant/organization

require_relative '../lib/quickbooks_mcp_server'

# ============================================
# Scenario 1: Single Tenant (ENV variables)
# ============================================

# Uses ENV variables (QUICKBOOKS_CLIENT_ID, etc.)
server = QuickbooksMCPServer.new

customers = server.search_customers(limit: 10)
puts "Found #{customers.length} customers"

# ============================================
# Scenario 2: Multi-Tenant (Explicit credentials)
# ============================================

# Organization 1
org1_server = QuickbooksMCPServer.new(
  client_id: 'org1_client_id',
  client_secret: 'org1_client_secret',
  refresh_token: 'org1_refresh_token',
  realm_id: 'org1_realm_id',
  environment: 'sandbox',
  server_context: {
    organization_id: 1,
    user_id: 123
  }
)

org1_customers = org1_server.search_customers(limit: 10)

# Organization 2 (different credentials)
org2_server = QuickbooksMCPServer.new(
  client_id: 'org2_client_id',
  client_secret: 'org2_client_secret',
  refresh_token: 'org2_refresh_token',
  realm_id: 'org2_realm_id',
  environment: 'production',
  server_context: {
    organization_id: 2,
    user_id: 456
  }
)

org2_customers = org2_server.search_customers(limit: 10)

# ============================================
# Rails Multi-Tenant Example
# ============================================

# Assuming you have an Organization model with QuickBooks credentials:
#
# class Organization < ApplicationRecord
#   has_many :users
#
#   # Columns: quickbooks_client_id, quickbooks_client_secret,
#   #          quickbooks_refresh_token, quickbooks_realm_id, quickbooks_environment
#
#   def quickbooks_server
#     QuickbooksMCPServer.new(
#       client_id: quickbooks_client_id,
#       client_secret: quickbooks_client_secret,
#       refresh_token: quickbooks_refresh_token,
#       realm_id: quickbooks_realm_id,
#       environment: quickbooks_environment || 'sandbox',
#       server_context: {
#         organization_id: id
#       }
#     )
#   end
# end

# Usage in controller:
#
# class CustomersController < ApplicationController
#   def index
#     qb = current_user.organization.quickbooks_server
#     @customers = qb.search_customers(limit: 50)
#   rescue QuickbooksMCPError => e
#     flash[:error] = "QuickBooks error: #{e.message}"
#     @customers = []
#   end
# end

# ============================================
# Service Object Pattern for Multi-Tenant
# ============================================

class QuickbooksService
  def initialize(organization)
    @organization = organization
    @qb = QuickbooksMCPServer.new(
      client_id: organization.quickbooks_client_id,
      client_secret: organization.quickbooks_client_secret,
      refresh_token: organization.quickbooks_refresh_token,
      realm_id: organization.quickbooks_realm_id,
      environment: organization.quickbooks_environment || 'sandbox',
      server_context: {
        organization_id: organization.id
      }
    )
  end

  def sync_customers
    qb_customers = @qb.search_customers(limit: 1000)

    qb_customers.each do |qb_customer|
      @organization.customers.find_or_initialize_by(
        quickbooks_id: qb_customer['Id']
      ).tap do |customer|
        customer.name = qb_customer['DisplayName']
        customer.email = qb_customer.dig('PrimaryEmailAddr', 'Address')
        customer.save!
      end
    end
  end

  def create_invoice_for_order(order)
    invoice_data = build_invoice_data(order)
    @qb.create_invoice(invoice_data)
  end

  private

  def build_invoice_data(order)
    {
      CustomerRef: { value: order.customer.quickbooks_id },
      Line: order.line_items.map { |item|
        {
          Amount: item.total,
          DetailType: 'SalesItemLineDetail',
          SalesItemLineDetail: {
            ItemRef: { value: item.product.quickbooks_id },
            Qty: item.quantity,
            UnitPrice: item.price
          }
        }
      }
    }
  end
end

# Usage:
# service = QuickbooksService.new(current_organization)
# service.sync_customers
# service.create_invoice_for_order(@order)

# ============================================
# Background Job for Multi-Tenant Sync
# ============================================

class SyncQuickbooksJob < ApplicationJob
  queue_as :default

  def perform(organization_id)
    organization = Organization.find(organization_id)
    service = QuickbooksService.new(organization)

    service.sync_customers
  end
end

# Schedule for all organizations:
# Organization.find_each do |org|
#   SyncQuickbooksJob.perform_later(org.id)
# end

# ============================================
# Testing with Different Credentials
# ============================================

# RSpec example:
#
# RSpec.describe QuickbooksService do
#   let(:organization) do
#     create(:organization,
#       quickbooks_client_id: 'test_client_id',
#       quickbooks_client_secret: 'test_client_secret',
#       quickbooks_refresh_token: 'test_refresh_token',
#       quickbooks_realm_id: 'test_realm_id',
#       quickbooks_environment: 'sandbox'
#     )
#   end
#
#   let(:service) { QuickbooksService.new(organization) }
#
#   describe '#sync_customers' do
#     it 'syncs customers from QuickBooks' do
#       # Mock QuickBooks API responses
#       # ...
#
#       expect { service.sync_customers }.to change { organization.customers.count }
#     end
#   end
# end

# ============================================
# Mixing ENV and Explicit Credentials
# ============================================

# You can also provide some credentials explicitly and let others fall back to ENV:
server = QuickbooksMCPServer.new(
  refresh_token: 'custom_refresh_token',
  realm_id: 'custom_realm_id'
  # client_id and client_secret will use ENV['QUICKBOOKS_CLIENT_ID'] and ENV['QUICKBOOKS_CLIENT_SECRET']
)
