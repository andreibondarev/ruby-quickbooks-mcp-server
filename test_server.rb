#!/usr/bin/env ruby

# Quick test script to verify the MCP server is working
# Usage: ruby test_server.rb

require 'json'
require 'open3'

def send_request(server_path, request)
  stdin, stdout, stderr, wait_thr = Open3.popen3(server_path)

  stdin.puts(request.to_json)
  stdin.close

  # Read response (one line for each JSON-RPC response)
  response_line = stdout.gets
  stdout.close

  error_output = stderr.read
  stderr.close

  warn error_output unless error_output.empty?

  response_line ? JSON.parse(response_line) : nil
rescue => e
  puts "Error: #{e.message}"
  nil
end

def test_tools_list(server_path)
  puts "\n=== Testing tools/list ==="

  request = {
    jsonrpc: '2.0',
    id: 1,
    method: 'tools/list',
    params: {}
  }

  response = send_request(server_path, request)

  if response && response['result'] && response['result']['tools']
    tools = response['result']['tools']
    puts "✓ Server returned #{tools.length} tools"

    puts "\nAvailable tools:"
    tools.each do |tool|
      puts "  - #{tool['name']}: #{tool['description']}"
    end

    # Verify expected tools
    expected_tools = [
      'create_customer', 'get_customer', 'update_customer', 'delete_customer', 'search_customers',
      'create_invoice', 'read_invoice', 'update_invoice', 'search_invoices',
      'create_estimate', 'get_estimate', 'update_estimate', 'delete_estimate', 'search_estimates'
    ]

    tool_names = tools.map { |t| t['name'] }
    missing = expected_tools - tool_names

    if missing.empty?
      puts "\n✓ All expected tools are present"
    else
      puts "\n✗ Missing tools: #{missing.join(', ')}"
    end

    true
  else
    puts "✗ Failed to get tools list"
    puts "Response: #{response.inspect}"
    false
  end
end

def test_initialize(server_path)
  puts "\n=== Testing initialize ==="

  request = {
    jsonrpc: '2.0',
    id: 0,
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: {
        name: 'test-client',
        version: '1.0.0'
      }
    }
  }

  response = send_request(server_path, request)

  if response && response['result']
    puts "✓ Server initialized successfully"
    puts "  Protocol Version: #{response['result']['protocolVersion']}"
    puts "  Server Name: #{response['result']['serverInfo']['name']}"
    puts "  Server Version: #{response['result']['serverInfo']['version']}"
    true
  else
    puts "✗ Failed to initialize"
    puts "Response: #{response.inspect}"
    false
  end
end

def main
  server_path = File.expand_path('bin/quickbooks_mcp_server', __dir__)

  unless File.exist?(server_path)
    puts "Error: Server executable not found at #{server_path}"
    exit 1
  end

  unless File.executable?(server_path)
    puts "Error: Server is not executable. Run: chmod +x #{server_path}"
    exit 1
  end

  puts "Testing QuickBooks MCP Server..."
  puts "Server path: #{server_path}"

  # Test initialize
  init_success = test_initialize(server_path)

  # Test tools list
  list_success = test_tools_list(server_path)

  puts "\n" + "=" * 50
  if init_success && list_success
    puts "✓ All tests passed!"
    puts "\nNext steps:"
    puts "1. Test with MCP Inspector: npx @modelcontextprotocol/inspector ruby #{server_path}"
    puts "2. Configure Claude Desktop (see README.md)"
    puts "3. Try calling tools with real QuickBooks data"
  else
    puts "✗ Some tests failed. Check the errors above."
    exit 1
  end
end

main
