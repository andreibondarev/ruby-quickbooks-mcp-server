# Example service wrapper for QuickBooks MCP in Rails
#
# This service provides a Ruby-friendly interface to the MCP server
# when running as a separate HTTP service.
#
# Place this file in: app/services/quickbooks_service.rb

require 'httparty'

class QuickbooksService
  include HTTParty

  def initialize(mcp_url: nil)
    @mcp_url = mcp_url || ENV['QUICKBOOKS_MCP_URL'] || 'http://localhost:3001'
    self.class.base_uri(@mcp_url)
  end

  # Customer methods
  def search_customers(criteria: [], limit: nil, offset: nil, asc: nil, desc: nil)
    call_tool('search_customers', {
      criteria: criteria,
      limit: limit,
      offset: offset,
      asc: asc,
      desc: desc
    }.compact)
  end

  def get_customer(id)
    call_tool('get_customer', { id: id })
  end

  def create_customer(customer_data)
    call_tool('create_customer', { customer: customer_data })
  end

  def update_customer(customer_data)
    call_tool('update_customer', { customer: customer_data })
  end

  def delete_customer(id)
    call_tool('delete_customer', { id: id })
  end

  # Invoice methods
  def search_invoices(criteria: [], limit: nil, offset: nil, asc: nil, desc: nil)
    call_tool('search_invoices', {
      criteria: criteria,
      limit: limit,
      offset: offset,
      asc: asc,
      desc: desc
    }.compact)
  end

  def read_invoice(id)
    call_tool('read_invoice', { id: id })
  end

  def create_invoice(invoice_data)
    call_tool('create_invoice', { invoice: invoice_data })
  end

  def update_invoice(invoice_data)
    call_tool('update_invoice', { invoice: invoice_data })
  end

  # Add more methods for other entities as needed...

  private

  def call_tool(tool_name, arguments)
    response = self.class.post('/', {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        jsonrpc: '2.0',
        id: SecureRandom.uuid,
        method: 'tools/call',
        params: {
          name: tool_name,
          arguments: arguments
        }
      }.to_json
    })

    result = JSON.parse(response.body)

    # Check for JSON-RPC errors
    if result['error']
      raise QuickbooksError.new(result['error']['message'], result['error']['code'])
    end

    # Return the result or content
    if result['result'] && result['result']['content']
      # Parse MCP tool response format
      parse_tool_response(result['result']['content'])
    else
      result['result']
    end
  rescue HTTParty::Error => e
    raise QuickbooksError.new("HTTP request failed: #{e.message}")
  end

  def parse_tool_response(content)
    # MCP tools return content as array of text blocks
    # Extract the actual data from the response
    if content.is_a?(Array)
      content.map { |item| item['text'] }.join("\n")
    else
      content
    end
  end
end

# Custom error class
class QuickbooksError < StandardError
  attr_reader :code

  def initialize(message, code = nil)
    super(message)
    @code = code
  end
end

# Usage example in a controller:
#
# class CustomersController < ApplicationController
#   def index
#     qb = QuickbooksService.new
#     @customers = qb.search_customers(
#       criteria: [
#         { field: 'Active', value: true, operator: '=' }
#       ],
#       limit: 50,
#       asc: 'DisplayName'
#     )
#   rescue QuickbooksError => e
#     flash[:error] = "QuickBooks error: #{e.message}"
#     @customers = []
#   end
#
#   def create
#     qb = QuickbooksService.new
#     result = qb.create_customer(customer_params)
#
#     redirect_to customers_path, notice: 'Customer created successfully'
#   rescue QuickbooksError => e
#     flash.now[:error] = "Failed to create customer: #{e.message}"
#     render :new
#   end
# end
