# API Reference

This document lists all the Ruby methods available on `QuickbooksMCPServer`.

## Initialization

### Using Environment Variables (Single Tenant)

```ruby
# Uses ENV['QUICKBOOKS_CLIENT_ID'], ENV['QUICKBOOKS_CLIENT_SECRET'], etc.
server = QuickbooksMCPServer.new

# With server context
server = QuickbooksMCPServer.new(
  server_context: {
    user_id: 123,
    organization_id: 456
  }
)
```

### Using Explicit Credentials (Multi-Tenant)

```ruby
server = QuickbooksMCPServer.new(
  client_id: 'your_client_id',
  client_secret: 'your_client_secret',
  refresh_token: 'your_refresh_token',
  realm_id: 'your_realm_id',
  environment: 'sandbox', # or 'production'
  redirect_uri: 'http://localhost:8000/callback',
  server_context: {
    user_id: 123,
    organization_id: 456
  }
)
```

### Mixed Approach

```ruby
# Use explicit credentials for some, ENV for others
server = QuickbooksMCPServer.new(
  refresh_token: organization.quickbooks_refresh_token,
  realm_id: organization.quickbooks_realm_id
  # client_id and client_secret will use ENV variables
)
```

**Parameters:**
- `client_id` - QuickBooks OAuth client ID (defaults to `ENV['QUICKBOOKS_CLIENT_ID']`)
- `client_secret` - QuickBooks OAuth client secret (defaults to `ENV['QUICKBOOKS_CLIENT_SECRET']`)
- `refresh_token` - OAuth refresh token (defaults to `ENV['QUICKBOOKS_REFRESH_TOKEN']`)
- `realm_id` - QuickBooks company/realm ID (defaults to `ENV['QUICKBOOKS_REALM_ID']`)
- `environment` - 'sandbox' or 'production' (defaults to `ENV['QUICKBOOKS_ENVIRONMENT']` or 'sandbox')
- `redirect_uri` - OAuth callback URL (defaults to `ENV['QUICKBOOKS_REDIRECT_URI']` or 'http://localhost:8000/callback')
- `server_context` - Hash of contextual data passed to tools (user_id, organization_id, etc.)

## Generic MCP Methods

### `list_tools`
Returns array of all available tools with their schemas.

```ruby
tools = server.list_tools
# => [{"name" => "search_customers", "description" => "...", ...}, ...]
```

### `call_tool(name, arguments = {})`
Call any tool by name with arguments.

```ruby
result = server.call_tool('search_customers', { limit: 10 })
```

### `list_prompts`
Returns array of all available prompts.

```ruby
prompts = server.list_prompts
```

### `get_prompt(name, arguments = {})`
Get a prompt by name with arguments.

```ruby
messages = server.get_prompt('my_prompt', { arg: 'value' })
```

### `handle_request(json_body)`
Handle raw JSON-RPC request (for MCP protocol clients).

```ruby
json_request = '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
json_response = server.handle_request(json_request)
```

## Customer Methods

### `search_customers(criteria: [], limit: nil, offset: nil, asc: nil, desc: nil)`
Search for customers matching criteria.

```ruby
customers = server.search_customers(
  criteria: [
    { field: 'Active', value: true, operator: '=' },
    { field: 'DisplayName', value: 'Acme%', operator: 'LIKE' }
  ],
  limit: 50,
  asc: 'DisplayName'
)
```

### `get_customer(id)`
Get a customer by ID.

```ruby
customer = server.get_customer('123')
# => {"Id" => "123", "DisplayName" => "Acme Corp", ...}
```

### `create_customer(customer_data)`
Create a new customer.

```ruby
customer = server.create_customer({
  DisplayName: 'Acme Corp',
  PrimaryEmailAddr: { Address: 'contact@acme.com' },
  PrimaryPhone: { FreeFormNumber: '555-1234' }
})
```

### `update_customer(customer_data)`
Update an existing customer.

```ruby
customer = server.update_customer({
  Id: '123',
  SyncToken: '0',
  DisplayName: 'Acme Corporation'
})
```

### `delete_customer(id, sync_token)`
Delete (deactivate) a customer.

```ruby
result = server.delete_customer('123', '0')
```

## Invoice Methods

### `search_invoices(criteria: [], limit: nil, offset: nil, asc: nil, desc: nil)`
Search for invoices.

```ruby
invoices = server.search_invoices(
  criteria: [
    { field: 'Balance', value: '0', operator: '>' }
  ],
  desc: 'TxnDate',
  limit: 20
)
```

### `read_invoice(id)`
Read an invoice by ID.

```ruby
invoice = server.read_invoice('456')
```

### `create_invoice(invoice_data)`
Create a new invoice.

```ruby
invoice = server.create_invoice({
  CustomerRef: { value: '123' },
  Line: [
    {
      Amount: 100.00,
      DetailType: 'SalesItemLineDetail',
      SalesItemLineDetail: {
        ItemRef: { value: '1' },
        Qty: 2,
        UnitPrice: 50.00
      }
    }
  ]
})
```

### `update_invoice(invoice_data)`
Update an existing invoice.

```ruby
invoice = server.update_invoice({
  Id: '456',
  SyncToken: '0',
  # ... updated fields
})
```

## Estimate Methods

### `search_estimates(criteria: [], limit: nil, offset: nil, asc: nil, desc: nil)`
Search for estimates.

```ruby
estimates = server.search_estimates(
  criteria: [
    { field: 'TxnStatus', value: 'Pending', operator: '=' }
  ],
  limit: 10
)
```

### `get_estimate(id)`
Get an estimate by ID.

```ruby
estimate = server.get_estimate('789')
```

### `create_estimate(estimate_data)`
Create a new estimate.

```ruby
estimate = server.create_estimate({
  CustomerRef: { value: '123' },
  Line: [
    {
      Amount: 500.00,
      DetailType: 'SalesItemLineDetail',
      SalesItemLineDetail: {
        ItemRef: { value: '1' }
      }
    }
  ]
})
```

### `update_estimate(estimate_data)`
Update an existing estimate.

```ruby
estimate = server.update_estimate({
  Id: '789',
  SyncToken: '0',
  # ... updated fields
})
```

### `delete_estimate(id)`
Delete an estimate.

```ruby
result = server.delete_estimate('789')
```

## Error Handling

All methods raise `QuickbooksMCPError` on failure:

```ruby
begin
  customer = server.get_customer('invalid_id')
rescue QuickbooksMCPError => e
  puts "Error: #{e.message}"
  puts "Code: #{e.code}"
end
```

## Search Criteria Format

Search criteria support flexible filtering:

```ruby
criteria: [
  # Simple equality
  { field: 'Active', value: true, operator: '=' },

  # Greater than
  { field: 'Balance', value: '100', operator: '>' },

  # LIKE for pattern matching
  { field: 'DisplayName', value: 'Acme%', operator: 'LIKE' },

  # IN for multiple values
  { field: 'Id', value: ['1', '2', '3'], operator: 'IN' }
]
```

Supported operators: `=`, `<`, `>`, `<=`, `>=`, `LIKE`, `IN`

## Other Available Tools

While not all tools have convenience methods, you can call any tool using `call_tool`:

```ruby
# Bills
server.call_tool('search_bills', { limit: 10 })
server.call_tool('get_bill', { id: '123' })
server.call_tool('create_bill', { bill: {...} })
server.call_tool('update_bill', { bill: {...} })
server.call_tool('delete_bill', { id: '123' })

# Vendors
server.call_tool('search_vendors', { limit: 10 })
server.call_tool('get_vendor', { id: '123' })
server.call_tool('create_vendor', { vendor: {...} })
server.call_tool('update_vendor', { vendor: {...} })
server.call_tool('delete_vendor', { id: '123' })

# Employees
server.call_tool('search_employees', { limit: 10 })
server.call_tool('get_employee', { id: '123' })
server.call_tool('create_employee', { employee: {...} })
server.call_tool('update_employee', { employee: {...} })

# Journal Entries
server.call_tool('search_journal_entries', { limit: 10 })
server.call_tool('get_journal_entry', { id: '123' })
server.call_tool('create_journal_entry', { journal_entry: {...} })
server.call_tool('update_journal_entry', { journal_entry: {...} })
server.call_tool('delete_journal_entry', { id: '123' })

# Bill Payments
server.call_tool('search_bill_payments', { limit: 10 })
server.call_tool('get_bill_payment', { id: '123' })
server.call_tool('create_bill_payment', { bill_payment: {...} })
server.call_tool('update_bill_payment', { bill_payment: {...} })
server.call_tool('delete_bill_payment', { id: '123' })

# Purchases
server.call_tool('search_purchases', { limit: 10 })
server.call_tool('get_purchase', { id: '123' })
server.call_tool('create_purchase', { purchase: {...} })
server.call_tool('update_purchase', { purchase: {...} })
server.call_tool('delete_purchase', { id: '123' })

# Accounts
server.call_tool('search_accounts', { limit: 10 })
server.call_tool('create_account', { account: {...} })
server.call_tool('update_account', { account: {...} })

# Items
server.call_tool('search_items', { limit: 10 })
server.call_tool('read_item', { id: '123' })
server.call_tool('create_item', { item: {...} })
server.call_tool('update_item', { item: {...} })
```

## Complete Example

```ruby
# Initialize
qb = QuickbooksMCPServer.new(
  server_context: { user_id: current_user.id }
)

# List all tools
tools = qb.list_tools
puts "#{tools.count} tools available"

# Search for active customers
customers = qb.search_customers(
  criteria: [{ field: 'Active', value: true, operator: '=' }],
  limit: 50,
  asc: 'DisplayName'
)

# Get first customer
customer = qb.get_customer(customers.first['Id'])

# Create an invoice for the customer
invoice = qb.create_invoice({
  CustomerRef: { value: customer['Id'] },
  Line: [
    {
      Amount: 100.00,
      DetailType: 'SalesItemLineDetail',
      SalesItemLineDetail: {
        ItemRef: { value: '1' },
        Qty: 1,
        UnitPrice: 100.00
      }
    }
  ]
})

puts "Created invoice ##{invoice['DocNumber']} for #{customer['DisplayName']}"
```
