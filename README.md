# QuickBooks Online MCP Server (Ruby)

A Ruby implementation of the Model Context Protocol (MCP) server for QuickBooks Online integration.

## Overview

This MCP server provides tools for interacting with QuickBooks Online, allowing you to create, read, update, delete, and search various QuickBooks entities through the Model Context Protocol.

## Features

Complete CRUD operations for the following QuickBooks entities:

- **Customers** - Create, Get, Update, Delete, Search
- **Invoices** - Create, Read, Update, Search
- **Estimates** - Create, Get, Update, Delete, Search
- **Bills** - Create, Get, Update, Delete, Search
- **Vendors** - Create, Get, Update, Delete, Search
- **Employees** - Create, Get, Update, Search
- **Journal Entries** - Create, Get, Update, Delete, Search
- **Bill Payments** - Create, Get, Update, Delete, Search
- **Purchases** - Create, Get, Update, Delete, Search
- **Accounts** - Create, Update, Search
- **Items** - Create, Read, Update, Search

## Prerequisites

- Ruby 3.0 or higher (tested with Ruby 3.0+)
- Bundler for dependency management
- A QuickBooks Online developer account
- QuickBooks app credentials (Client ID and Client Secret)

## Installation

1. Clone this repository or copy the files to your local machine

2. Install dependencies:
```bash
bundle install
```

3. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

4. Configure your QuickBooks credentials in the `.env` file:
```env
QUICKBOOKS_CLIENT_ID=your_client_id
QUICKBOOKS_CLIENT_SECRET=your_client_secret
QUICKBOOKS_ENVIRONMENT=sandbox
```

## QuickBooks Setup

1. Go to the [Intuit Developer Portal](https://developer.intuit.com/)
2. Create a new app or select an existing one
3. Get the Client ID and Client Secret from the app's keys section
4. Add `http://localhost:8000/callback` to the app's Redirect URIs

## Authentication

There are two ways to authenticate with QuickBooks Online:

### Option 1: Using Environment Variables

If you already have a refresh token and realm ID, add them to your `.env` file:

```env
QUICKBOOKS_REFRESH_TOKEN=your_refresh_token
QUICKBOOKS_REALM_ID=your_realm_id
```

### Option 2: Using the OAuth Flow

If you don't have a refresh token, the server will automatically start an OAuth flow on first use:

1. Run the server
2. A browser window will open automatically
3. Sign in to QuickBooks and authorize the app
4. The tokens will be saved to your `.env` file automatically
5. You can close the browser window

## Testing

Before using the server in production, test it to make sure everything works:

### Quick Test

Run the included test script:
```bash
ruby test_server.rb
```

This will verify:
- Server starts correctly
- All tools are registered
- Basic MCP protocol communication works

### Comprehensive Testing

For detailed testing instructions including:
- Using MCP Inspector (recommended)
- Manual stdio testing
- Claude Desktop integration
- Automated testing with RSpec

See **[TESTING.md](TESTING.md)** for complete testing guide.

## Usage

### Running as Stdio Server (for Claude Desktop)

Make the executable file runnable (first time only):
```bash
chmod +x bin/quickbooks_mcp_server
```

Run the server:
```bash
./bin/quickbooks_mcp_server
```

Or using Ruby directly:
```bash
ruby bin/quickbooks_mcp_server
```

### Running as HTTP Server (for Rails/Web Apps)

Run the server with HTTP transport:
```bash
chmod +x bin/quickbooks_mcp_http
PORT=3001 ./bin/quickbooks_mcp_http
```

With stateless mode (recommended for production/scaling):
```bash
PORT=3001 STATELESS=true ./bin/quickbooks_mcp_http
```

The server will be available at `http://localhost:3001` and accepts JSON-RPC 2.0 requests.

### Available Tools

The server exposes the following MCP tools:

#### Customer Operations
- `create_customer` - Create a new customer
- `get_customer` - Get customer by ID
- `update_customer` - Update a customer
- `delete_customer` - Delete (deactivate) a customer
- `search_customers` - Search customers with filters

#### Invoice Operations
- `create_invoice` - Create a new invoice
- `read_invoice` - Read invoice by ID
- `update_invoice` - Update an invoice
- `search_invoices` - Search invoices with filters

#### Estimate Operations
- `create_estimate` - Create a new estimate
- `get_estimate` - Get estimate by ID
- `update_estimate` - Update an estimate
- `delete_estimate` - Delete an estimate
- `search_estimates` - Search estimates with filters

#### Bill Operations
- `create_bill` - Create a new bill
- `get_bill` - Get bill by ID
- `update_bill` - Update a bill
- `delete_bill` - Delete a bill
- `search_bills` - Search bills with filters

#### Vendor Operations
- `create_vendor` - Create a new vendor
- `get_vendor` - Get vendor by ID
- `update_vendor` - Update a vendor
- `delete_vendor` - Delete (deactivate) a vendor
- `search_vendors` - Search vendors with filters

#### Employee Operations
- `create_employee` - Create a new employee
- `get_employee` - Get employee by ID
- `update_employee` - Update an employee
- `search_employees` - Search employees with filters

#### Journal Entry Operations
- `create_journal_entry` - Create a new journal entry
- `get_journal_entry` - Get journal entry by ID
- `update_journal_entry` - Update a journal entry
- `delete_journal_entry` - Delete a journal entry
- `search_journal_entries` - Search journal entries with filters

#### Bill Payment Operations
- `create_bill_payment` - Create a new bill payment
- `get_bill_payment` - Get bill payment by ID
- `update_bill_payment` - Update a bill payment
- `delete_bill_payment` - Delete a bill payment
- `search_bill_payments` - Search bill payments with filters

#### Purchase Operations
- `create_purchase` - Create a new purchase
- `get_purchase` - Get purchase by ID
- `update_purchase` - Update a purchase
- `delete_purchase` - Delete a purchase
- `search_purchases` - Search purchases with filters

#### Account Operations
- `create_account` - Create a new account
- `update_account` - Update an account
- `search_accounts` - Search accounts with filters

#### Item Operations
- `create_item` - Create a new item
- `read_item` - Read item by ID
- `update_item` - Update an item
- `search_items` - Search items with filters

### Search Criteria

All search operations support flexible filtering:

```ruby
# Simple search
{
  criteria: [
    { field: "DisplayName", value: "John Doe", operator: "=" }
  ]
}

# Advanced search with pagination and sorting
{
  criteria: [
    { field: "Active", value: true, operator: "=" }
  ],
  limit: 10,
  offset: 0,
  asc: "DisplayName"
}
```

Supported operators: `=`, `<`, `>`, `<=`, `>=`, `LIKE`, `IN`

## Ruby API

The server provides both a JSON-RPC interface (for MCP clients) and a Ruby-friendly API (for direct use in Ruby code):

```ruby
# Simple usage (uses ENV variables)
qb = QuickbooksMCPServer.new

# Multi-tenant usage (explicit credentials)
qb = QuickbooksMCPServer.new(
  client_id: organization.quickbooks_client_id,
  client_secret: organization.quickbooks_client_secret,
  refresh_token: organization.quickbooks_refresh_token,
  realm_id: organization.quickbooks_realm_id,
  environment: 'sandbox'
)

# Ruby-friendly methods
customers = qb.search_customers(limit: 50)
customer = qb.get_customer('123')
invoice = qb.create_invoice(invoice_data)

# Generic tool calling
result = qb.call_tool('search_vendors', { limit: 10 })

# List available tools
tools = qb.list_tools
```

See **[API_REFERENCE.md](API_REFERENCE.md)** for complete method documentation.

## Using in Your Rails App

The easiest way to include this in your Rails app is as a local gem:

```ruby
# In your Rails app's Gemfile
gem 'quickbooks_mcp', path: '../ruby-quickbooks-mcp-server'

# Or from git
gem 'quickbooks_mcp', git: 'https://github.com/yourusername/ruby-quickbooks-mcp-server.git'
```

Then use it with the Ruby-friendly API:

```ruby
# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  def index
    qb = QuickbooksMCPServer.new(
      server_context: { user_id: current_user.id }
    )

    @customers = qb.search_customers(
      criteria: [{ field: 'Active', value: true, operator: '=' }],
      limit: 50
    )
  end

  def show
    qb = QuickbooksMCPServer.new
    @customer = qb.get_customer(params[:id])
  end
end
```

Or handle raw MCP JSON-RPC requests:

```ruby
# app/controllers/quickbooks_mcp_controller.rb
class QuickbooksMcpController < ApplicationController
  def handle
    server = QuickbooksMCPServer.new(
      server_context: { user_id: current_user&.id }
    )
    render json: server.handle_request(request.body.read)
  end
end
```

See **[RAILS_SETUP.md](RAILS_SETUP.md)** for all integration options (local gem, git gem, copy files, etc.)

## Rails Integration

Want to use this MCP server in your Rails app? See **[RAILS_INTEGRATION.md](RAILS_INTEGRATION.md)** for:

- Direct Rails controller integration
- Running as a separate HTTP service
- Multi-tenant support
- Authentication and security
- Performance optimization
- Complete working examples

Quick example for Rails:

```ruby
# app/controllers/quickbooks_mcp_controller.rb
class QuickbooksMcpController < ApplicationController
  def handle
    server = QuickbooksMCPServer.new(
      server_context: { user_id: current_user&.id }
    )
    render json: server.handle_request(request.body.read)
  end
end
```

## Project Structure

```
ruby-quickbooks-mcp-server/
├── Gemfile                    # Ruby dependencies
├── README.md                  # This file
├── RAILS_INTEGRATION.md       # Rails integration guide
├── TESTING.md                 # Testing guide
├── .env.example              # Environment variables template
├── bin/
│   ├── quickbooks_mcp_server # Stdio server (for Claude Desktop)
│   └── quickbooks_mcp_http   # HTTP server (for Rails/web)
├── lib/
│   ├── quickbooks_mcp_server.rb  # Main server setup
│   ├── quickbooks_client.rb      # QuickBooks OAuth client
│   ├── helpers/
│   │   ├── format_error.rb       # Error formatting
│   │   └── search_criteria_builder.rb  # Query builder
│   └── tools/
│       ├── customer_tools.rb     # Customer CRUD tools
│       ├── invoice_tools.rb      # Invoice CRUD tools
│       ├── estimate_tools.rb     # Estimate CRUD tools
│       ├── bill_tools.rb         # Bill CRUD tools
│       ├── vendor_tools.rb       # Vendor CRUD tools
│       ├── employee_tools.rb     # Employee CRUD tools
│       ├── journal_entry_tools.rb # Journal Entry CRUD tools
│       ├── bill_payment_tools.rb  # Bill Payment CRUD tools
│       ├── purchase_tools.rb     # Purchase CRUD tools
│       ├── account_tools.rb      # Account CRUD tools
│       └── item_tools.rb         # Item CRUD tools
└── examples/
    ├── rails_controller_example.rb   # Rails controller example
    └── quickbooks_service_wrapper.rb # Service wrapper example
```

## Error Handling

All tools include comprehensive error handling and will return descriptive error messages if operations fail. Common errors include:

- Authentication failures (invalid or expired tokens)
- Missing required fields
- Invalid entity IDs
- QuickBooks API errors

## Development

This server uses:
- `mcp` gem (main branch) for MCP protocol implementation
- `quickbooks-ruby` (~> 2.0) for QuickBooks API access
- `oauth2` (~> 1.4) for OAuth 2.0 authentication
- `dotenv` (~> 3.1) for environment variable management
- `puma` (~> 6.5) for OAuth callback server
- `rackup` (~> 2.2) for Rack application support

## Transport Modes

This server supports two transport modes:

### Stdio Transport (for Claude Desktop)
```bash
./bin/quickbooks_mcp_server
```
Use for: Claude Desktop, MCP Inspector, CLI tools

### HTTP Transport (for Rails/Web Apps)
```bash
PORT=3001 ./bin/quickbooks_mcp_http
```
Use for: Rails apps, microservices, web APIs

See **[DEPLOYMENT.md](DEPLOYMENT.md)** for detailed deployment options and production best practices.

## Differences from TypeScript Version

This Ruby implementation provides feature parity with the TypeScript version while following Ruby conventions:

- Uses Ruby classes and modules instead of TypeScript interfaces
- Uses `snake_case` for method and variable names
- Leverages Ruby blocks for tool definitions
- Uses the `quickbooks-ruby` gem instead of `node-quickbooks`
- Supports both Stdio and StreamableHTTP transports
- Can be embedded directly in Rails apps
- Maintains the same tool names and functionality for consistency

## Troubleshooting

### "QuickBooks not authenticated" error

Make sure your `.env` file contains valid credentials and tokens. If you're using OAuth flow, ensure:
1. Your Client ID and Client Secret are correct
2. The redirect URI matches what's configured in your QuickBooks app
3. Port 8000 is available for the OAuth callback server

### Token expiration

Refresh tokens expire after 100 days of inactivity. If your token expires, simply delete the `QUICKBOOKS_REFRESH_TOKEN` from your `.env` file and run the server again to re-authenticate.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
