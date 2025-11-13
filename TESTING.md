# Testing the QuickBooks MCP Server

## Prerequisites

Before testing, make sure you have:
1. Configured your `.env` file with QuickBooks credentials
2. Run `bundle install` to install dependencies
3. Made the executable runnable: `chmod +x bin/quickbooks_mcp_server`

## Method 1: Using MCP Inspector (Recommended)

The MCP Inspector is the official tool for testing MCP servers with a web UI.

### Installation

```bash
npx @modelcontextprotocol/inspector
```

### Usage (Stdio Mode)

1. Start the inspector:
```bash
npx @modelcontextprotocol/inspector ruby bin/quickbooks_mcp_server
```

2. Open your browser to the URL shown (typically http://localhost:5173)

3. You'll see:
   - List of available tools
   - Ability to call tools with parameters
   - Real-time request/response inspection
   - Schema validation

### Usage (HTTP Mode)

1. Start the HTTP server:
```bash
PORT=3001 ./bin/quickbooks_mcp_http
```

2. In another terminal, use curl or any HTTP client:
```bash
# List tools
curl -X POST http://localhost:3001 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'

# Call a tool
curl -X POST http://localhost:3001 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "search_customers",
      "arguments": {
        "limit": 5
      }
    }
  }'
```

### Testing a Tool

In the MCP Inspector:

1. Select a tool (e.g., "search_customers")
2. Enter parameters in the JSON editor:
```json
{
  "criteria": [
    {"field": "Active", "value": true, "operator": "="}
  ],
  "limit": 5
}
```
3. Click "Run Tool"
4. View the response

## Method 2: Manual stdio Testing

You can manually send JSON-RPC messages to test the server.

### Start the server:
```bash
./bin/quickbooks_mcp_server
```

### Send initialization request:
```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}}}
```

### List available tools:
```json
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
```

### Call a tool:
```json
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search_customers","arguments":{"limit":5}}}
```

Press Ctrl+D to send EOF when done.

## Method 3: Using Claude Desktop

Add the server to your Claude Desktop configuration.

### macOS Configuration

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "quickbooks": {
      "command": "ruby",
      "args": [
        "/Users/andrei/Code/qbo-mcp-server/ruby-quickbooks-mcp-server/bin/quickbooks_mcp_server"
      ],
      "env": {
        "QUICKBOOKS_CLIENT_ID": "your_client_id",
        "QUICKBOOKS_CLIENT_SECRET": "your_client_secret",
        "QUICKBOOKS_REFRESH_TOKEN": "your_refresh_token",
        "QUICKBOOKS_REALM_ID": "your_realm_id",
        "QUICKBOOKS_ENVIRONMENT": "sandbox"
      }
    }
  }
}
```

### Testing in Claude Desktop

1. Restart Claude Desktop
2. Look for the tools icon (hammer/wrench) in the input area
3. You should see all QuickBooks tools available
4. Ask Claude to use them:
   - "Search for active customers in QuickBooks"
   - "Create a new customer named John Doe"
   - "Get customer with ID 123"

## Method 4: Automated Testing with RSpec

Create a test suite for your server.

### Install RSpec:
```bash
# Add to Gemfile
gem 'rspec', '~> 3.13', group: :test

bundle install
```

### Create test file (`spec/quickbooks_mcp_server_spec.rb`):
```ruby
require 'json'
require 'open3'

RSpec.describe 'QuickbooksMCPServer' do
  let(:server_cmd) { './bin/quickbooks_mcp_server' }

  def send_request(method, params = {}, id = 1)
    request = {
      jsonrpc: '2.0',
      id: id,
      method: method,
      params: params
    }.to_json

    stdin, stdout, stderr, wait_thr = Open3.popen3(server_cmd)
    stdin.puts(request)
    stdin.close

    response = stdout.read
    stdout.close
    stderr.close

    JSON.parse(response)
  end

  it 'responds to tools/list' do
    response = send_request('tools/list')

    expect(response['result']['tools']).to be_an(Array)
    expect(response['result']['tools'].length).to be > 0

    # Check for specific tools
    tool_names = response['result']['tools'].map { |t| t['name'] }
    expect(tool_names).to include('create_customer')
    expect(tool_names).to include('search_customers')
  end

  it 'has proper schema for create_customer tool' do
    response = send_request('tools/list')
    create_customer = response['result']['tools'].find { |t| t['name'] == 'create_customer' }

    expect(create_customer).not_to be_nil
    expect(create_customer['description']).to be_a(String)
    expect(create_customer['inputSchema']).to be_a(Hash)
  end
end
```

### Run tests:
```bash
bundle exec rspec
```

## Common Test Scenarios

### Test 1: Search Customers
```json
{
  "name": "search_customers",
  "arguments": {
    "criteria": [
      {"field": "Active", "value": true, "operator": "="}
    ],
    "limit": 10,
    "asc": "DisplayName"
  }
}
```

### Test 2: Create Customer
```json
{
  "name": "create_customer",
  "arguments": {
    "customer": {
      "DisplayName": "Test Customer",
      "PrimaryEmailAddr": {
        "Address": "test@example.com"
      }
    }
  }
}
```

### Test 3: Search Invoices
```json
{
  "name": "search_invoices",
  "arguments": {
    "criteria": [
      {"field": "Balance", "value": "0", "operator": ">"}
    ],
    "desc": "TxnDate",
    "limit": 20
  }
}
```

### Test 4: Get Customer by ID
```json
{
  "name": "get_customer",
  "arguments": {
    "id": "1"
  }
}
```

## Debugging Tips

### Enable Debug Logging

Add to your server code (temporarily):
```ruby
MCP.configure do |config|
  config.instrumentation_callback = ->(data) {
    STDERR.puts "MCP Event: #{data.inspect}"
  }

  config.exception_reporter = ->(exception, context) {
    STDERR.puts "Error: #{exception.message}"
    STDERR.puts exception.backtrace.join("\n")
  }
end
```

### Check Server Logs

Run the server and check stderr:
```bash
./bin/quickbooks_mcp_server 2> errors.log
```

### Verify QuickBooks Authentication

Test authentication separately:
```ruby
require_relative 'lib/quickbooks_client'

client = QuickbooksClient.new(
  client_id: ENV['QUICKBOOKS_CLIENT_ID'],
  client_secret: ENV['QUICKBOOKS_CLIENT_SECRET'],
  refresh_token: ENV['QUICKBOOKS_REFRESH_TOKEN'],
  realm_id: ENV['QUICKBOOKS_REALM_ID'],
  environment: 'sandbox'
)

client.authenticate
puts "✓ Authentication successful!"
```

## Troubleshooting

### OAuth Flow Not Starting
- Check that port 8000 is available
- Verify redirect URI matches QuickBooks app settings
- Make sure Puma gem is installed

### "Tool not found" errors
- Verify all tool files are loaded in `lib/quickbooks_mcp_server.rb`
- Check tool registration order

### QuickBooks API errors
- Verify your sandbox/production environment setting
- Check that realm_id is correct
- Ensure refresh_token hasn't expired (100 days)
- Check QuickBooks API response for specific error messages

## Performance Testing

Test with multiple concurrent requests:

```bash
# Using Apache Bench (if testing via HTTP wrapper)
ab -n 100 -c 10 http://localhost:3000/mcp

# Or test stdio throughput
for i in {1..10}; do
  echo '{"jsonrpc":"2.0","id":'$i',"method":"tools/list"}' | ./bin/quickbooks_mcp_server &
done
wait
```

## Next Steps

1. Start with MCP Inspector for interactive testing
2. Build a test suite with common scenarios
3. Test OAuth flow in a fresh environment
4. Verify all CRUD operations work correctly
5. Test error handling with invalid inputs
6. Monitor performance with realistic data volumes
