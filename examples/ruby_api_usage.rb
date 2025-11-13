# Example: Using QuickBooks MCP Server with Ruby-friendly API
#
# This shows how to use the convenience methods instead of JSON-RPC

require_relative '../lib/quickbooks_mcp_server'

# Initialize the server
server = QuickbooksMCPServer.new(
  server_context: {
    user_id: 123,
    organization_id: 456
  }
)

# ============================================
# Generic MCP methods
# ============================================

# List all available tools
tools = server.list_tools
puts "Available tools: #{tools.map { |t| t['name'] }.join(', ')}"

# Call any tool by name
result = server.call_tool('search_customers', { limit: 5 })
puts "Tool result: #{result}"

# ============================================
# QuickBooks-specific convenience methods
# ============================================

# Search customers with Ruby-friendly API
customers = server.search_customers(
  criteria: [
    { field: 'Active', value: true, operator: '=' }
  ],
  limit: 10,
  asc: 'DisplayName'
)
puts "Found #{customers.length} customers"

# Get a specific customer
customer = server.get_customer('123')
puts "Customer: #{customer['DisplayName']}"

# Create a new customer
new_customer = server.create_customer({
  DisplayName: 'Acme Corp',
  PrimaryEmailAddr: {
    Address: 'contact@acme.com'
  }
})
puts "Created customer with ID: #{new_customer['Id']}"

# Update customer
updated_customer = server.update_customer({
  Id: new_customer['Id'],
  SyncToken: new_customer['SyncToken'],
  DisplayName: 'Acme Corporation'
})

# Search invoices
invoices = server.search_invoices(
  criteria: [
    { field: 'Balance', value: '0', operator: '>' }
  ],
  limit: 20,
  desc: 'TxnDate'
)
puts "Found #{invoices.length} unpaid invoices"

# Read an invoice
invoice = server.read_invoice('456')
puts "Invoice total: $#{invoice['TotalAmt']}"

# Create an invoice
new_invoice = server.create_invoice({
  CustomerRef: { value: customer['Id'] },
  Line: [
    {
      Amount: 100.00,
      DetailType: 'SalesItemLineDetail',
      SalesItemLineDetail: {
        ItemRef: { value: '1' }
      }
    }
  ]
})
puts "Created invoice ##{new_invoice['DocNumber']}"

# Search estimates
estimates = server.search_estimates(limit: 10)
puts "Found #{estimates.length} estimates"

# ============================================
# Error handling
# ============================================

begin
  server.get_customer('invalid_id')
rescue QuickbooksMCPError => e
  puts "Error: #{e.message} (code: #{e.code})"
end

# ============================================
# Usage in Rails Controller
# ============================================

# class CustomersController < ApplicationController
#   def index
#     qb = QuickbooksMCPServer.new(
#       server_context: { user_id: current_user.id }
#     )
#
#     @customers = qb.search_customers(
#       criteria: [
#         { field: 'Active', value: true, operator: '=' }
#       ],
#       limit: params[:limit] || 50,
#       asc: 'DisplayName'
#     )
#   rescue QuickbooksMCPError => e
#     flash[:error] = "QuickBooks error: #{e.message}"
#     @customers = []
#   end
#
#   def show
#     qb = QuickbooksMCPServer.new(
#       server_context: { user_id: current_user.id }
#     )
#
#     @customer = qb.get_customer(params[:id])
#   rescue QuickbooksMCPError => e
#     flash[:error] = "Customer not found: #{e.message}"
#     redirect_to customers_path
#   end
#
#   def create
#     qb = QuickbooksMCPServer.new(
#       server_context: { user_id: current_user.id }
#     )
#
#     @customer = qb.create_customer(customer_params.to_h)
#     redirect_to customer_path(@customer['Id']), notice: 'Customer created'
#   rescue QuickbooksMCPError => e
#     flash.now[:error] = "Failed to create customer: #{e.message}"
#     render :new
#   end
# end

# ============================================
# Usage in Service Objects
# ============================================

# class QuickbooksService
#   def initialize(user)
#     @user = user
#     @qb = QuickbooksMCPServer.new(
#       server_context: { user_id: user.id }
#     )
#   end
#
#   def sync_customers
#     customers = @qb.search_customers(limit: 1000)
#
#     customers.each do |qb_customer|
#       Customer.find_or_initialize_by(quickbooks_id: qb_customer['Id']).tap do |customer|
#         customer.name = qb_customer['DisplayName']
#         customer.email = qb_customer.dig('PrimaryEmailAddr', 'Address')
#         customer.save!
#       end
#     end
#   end
#
#   def create_invoice_from_order(order)
#     invoice_data = {
#       CustomerRef: { value: order.customer.quickbooks_id },
#       Line: order.line_items.map { |item|
#         {
#           Amount: item.total,
#           DetailType: 'SalesItemLineDetail',
#           SalesItemLineDetail: {
#             ItemRef: { value: item.product.quickbooks_id },
#             Qty: item.quantity,
#             UnitPrice: item.price
#           }
#         }
#       }
#     }
#
#     @qb.create_invoice(invoice_data)
#   end
# end
