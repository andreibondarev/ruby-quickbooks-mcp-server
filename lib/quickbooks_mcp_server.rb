require 'dotenv/load'
require 'mcp'
require 'json'
require 'securerandom'

require_relative 'quickbooks_client'
require_relative 'tools/customer_tools'
require_relative 'tools/invoice_tools'
require_relative 'tools/estimate_tools'
require_relative 'tools/bill_tools'
require_relative 'tools/vendor_tools'
require_relative 'tools/employee_tools'
require_relative 'tools/journal_entry_tools'
require_relative 'tools/bill_payment_tools'
require_relative 'tools/purchase_tools'
require_relative 'tools/account_tools'
require_relative 'tools/item_tools'

class QuickbooksMCPServer
  attr_reader :server, :qb_client

  def initialize(
    server_context: {},
    client_id: nil,
    client_secret: nil,
    refresh_token: nil,
    realm_id: nil,
    environment: nil,
    redirect_uri: nil
  )
    # Use provided credentials or fall back to environment variables
    client_id ||= ENV['QUICKBOOKS_CLIENT_ID']
    client_secret ||= ENV['QUICKBOOKS_CLIENT_SECRET']
    refresh_token ||= ENV['QUICKBOOKS_REFRESH_TOKEN']
    realm_id ||= ENV['QUICKBOOKS_REALM_ID']
    environment ||= ENV['QUICKBOOKS_ENVIRONMENT'] || 'sandbox'
    redirect_uri ||= ENV['QUICKBOOKS_REDIRECT_URI'] || 'http://localhost:8000/callback'

    # Validate required credentials
    unless client_id && client_secret
      raise ArgumentError, 'client_id and client_secret must be provided or set in environment variables (QUICKBOOKS_CLIENT_ID, QUICKBOOKS_CLIENT_SECRET)'
    end

    # Initialize QuickBooks client
    @qb_client = QuickbooksClient.new(
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      realm_id: realm_id,
      environment: environment,
      redirect_uri: redirect_uri
    )

    # Create MCP server
    @server = MCP::Server.new(
      name: 'quickbooks_online_mcp_server',
      version: '1.0.0',
      server_context: server_context
    )

    register_tools
  end

  def register_tools
    Tools::CustomerTools.register(@server, @qb_client)
    Tools::InvoiceTools.register(@server, @qb_client)
    Tools::EstimateTools.register(@server, @qb_client)
    Tools::BillTools.register(@server, @qb_client)
    Tools::VendorTools.register(@server, @qb_client)
    Tools::EmployeeTools.register(@server, @qb_client)
    Tools::JournalEntryTools.register(@server, @qb_client)
    Tools::BillPaymentTools.register(@server, @qb_client)
    Tools::PurchaseTools.register(@server, @qb_client)
    Tools::AccountTools.register(@server, @qb_client)
    Tools::ItemTools.register(@server, @qb_client)
  end

  # Run with stdio transport (for CLI usage)
  def self.run_stdio
    instance = new
    transport = MCP::Server::Transports::StdioTransport.new(instance.server)
    transport.open
  end

  # Run with HTTP transport (for Rails/web usage)
  def self.run_http(port: 3000, stateless: false)
    require 'rack'
    require 'puma'

    instance = new

    # Create Rack app that handles MCP JSON-RPC requests
    app = lambda do |env|
      request = Rack::Request.new(env)

      if request.post?
        begin
          body = request.body.read
          response = instance.handle_request(body)

          [200, { 'Content-Type' => 'application/json' }, [response]]
        rescue => e
          error_response = {
            jsonrpc: '2.0',
            error: {
              code: -32603,
              message: "Internal error: #{e.message}"
            }
          }.to_json

          [500, { 'Content-Type' => 'application/json' }, [error_response]]
        end
      else
        [405, { 'Content-Type' => 'text/plain' }, ['Method Not Allowed - POST required']]
      end
    end

    puts "Starting QuickBooks MCP Server on http://0.0.0.0:#{port}"
    puts "Stateless mode: #{stateless}"
    puts "Try: curl -X POST http://localhost:#{port} -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}'"
    puts "Press Ctrl+C to stop"
    puts

    # Start Puma server
    Puma::Server.new(app).tap do |server|
      server.add_tcp_listener '0.0.0.0', port
      server.run.join
    end
  end

  # For Rails integration - handle JSON directly
  def handle_request(json_body)
    @server.handle_json(json_body)
  end

  # Convenience methods for Ruby usage

  def list_tools
    request = build_request('tools/list')
    response = handle_json_rpc(request)
    response.dig('result', 'tools')
  end

  def call_tool(name, arguments = {})
    request = build_request('tools/call', {
      name: name,
      arguments: arguments
    })
    response = handle_json_rpc(request)
    parse_tool_response(response)
  end

  def list_prompts
    request = build_request('prompts/list')
    response = handle_json_rpc(request)
    response.dig('result', 'prompts')
  end

  def get_prompt(name, arguments = {})
    request = build_request('prompts/get', {
      name: name,
      arguments: arguments
    })
    response = handle_json_rpc(request)
    response.dig('result', 'messages')
  end

  # QuickBooks-specific convenience methods

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

  def search_estimates(criteria: [], limit: nil, offset: nil, asc: nil, desc: nil)
    call_tool('search_estimates', {
      criteria: criteria,
      limit: limit,
      offset: offset,
      asc: asc,
      desc: desc
    }.compact)
  end

  def get_estimate(id)
    call_tool('get_estimate', { id: id })
  end

  def create_estimate(estimate_data)
    call_tool('create_estimate', { estimate: estimate_data })
  end

  def update_estimate(estimate_data)
    call_tool('update_estimate', { estimate: estimate_data })
  end

  def delete_estimate(id)
    call_tool('delete_estimate', { id: id })
  end

  private

  def build_request(method, params = {})
    {
      jsonrpc: '2.0',
      id: SecureRandom.uuid,
      method: method,
      params: params
    }
  end

  def handle_json_rpc(request)
    json_response = @server.handle_json(request.to_json)
    response = JSON.parse(json_response)

    # Check for errors
    if response['error']
      raise QuickbooksMCPError.new(
        response['error']['message'],
        response['error']['code']
      )
    end

    response
  end

  def parse_tool_response(response)
    # Extract the actual data from MCP tool response format
    content = response.dig('result', 'content')
    return nil unless content

    if content.is_a?(Array)
      # Parse JSON from text content if possible
      texts = content.map { |item| item['text'] }.compact

      # Try to parse as JSON
      begin
        parsed = texts.map { |text| JSON.parse(text) }
        parsed.length == 1 ? parsed.first : parsed
      rescue JSON::ParserError
        texts.length == 1 ? texts.first : texts
      end
    else
      content
    end
  end
end

# Custom error class
class QuickbooksMCPError < StandardError
  attr_reader :code

  def initialize(message, code = nil)
    super(message)
    @code = code
  end
end
