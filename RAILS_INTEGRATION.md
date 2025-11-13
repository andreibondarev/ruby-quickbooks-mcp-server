# Rails Integration Guide

This guide shows how to integrate the QuickBooks MCP server into your Rails application.

## Overview

There are three approaches to integrating the MCP server with Rails:

1. **Direct Integration** (Recommended) - Embed the MCP server as a Rails controller endpoint
2. **Separate HTTP Service** - Run the MCP server as a standalone HTTP service
3. **Stdio Service** - Run as a background process and communicate via stdio

## Approach 1: Direct Rails Integration (Recommended)

Integrate the MCP server directly into your Rails app as a controller endpoint.

### Step 1: Add to Gemfile

```ruby
# Gemfile
gem 'mcp', '~> 0.7'
gem 'quickbooks-ruby', '~> 1.1'
gem 'oauth2', '~> 2.0'
```

### Step 2: Copy the MCP Server Code

Copy the `lib` directory into your Rails app:

```bash
cp -r ruby-quickbooks-mcp-server/lib app/services/quickbooks_mcp
```

Or add as a gem by creating a local gem or using a git submodule.

### Step 3: Create a Rails Controller

```ruby
# app/controllers/quickbooks_mcp_controller.rb
class QuickbooksMcpController < ApplicationController
  skip_before_action :verify_authenticity_token

  def handle
    server = get_or_create_server

    # Handle the JSON-RPC request
    response = server.handle_request(request.body.read)

    render json: response
  end

  private

  def get_or_create_server
    # Option A: Create a new server instance per request (stateless)
    @server ||= QuickbooksMCPServer.new(
      server_context: {
        user_id: current_user&.id,
        request_id: request.uuid
      }
    )

    # Option B: Use a singleton (for session-based state)
    # QuickbooksMCPServer.instance
  end
end
```

### Step 4: Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  post '/mcp/quickbooks', to: 'quickbooks_mcp#handle'
end
```

### Step 5: Configure Environment

```ruby
# config/initializers/quickbooks_mcp.rb
QuickbooksMCP::Config = {
  client_id: ENV['QUICKBOOKS_CLIENT_ID'],
  client_secret: ENV['QUICKBOOKS_CLIENT_SECRET'],
  refresh_token: ENV['QUICKBOOKS_REFRESH_TOKEN'],
  realm_id: ENV['QUICKBOOKS_REALM_ID'],
  environment: ENV['QUICKBOOKS_ENVIRONMENT'] || 'sandbox'
}
```

### Step 6: Add Authentication (Optional)

```ruby
# app/controllers/quickbooks_mcp_controller.rb
class QuickbooksMcpController < ApplicationController
  before_action :authenticate_user!
  before_action :check_api_key

  private

  def check_api_key
    api_key = request.headers['X-API-Key']
    unless api_key == ENV['MCP_API_KEY']
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
```

### Usage from Client

```javascript
// Frontend JavaScript
const response = await fetch('/mcp/quickbooks', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'your-api-key'
  },
  body: JSON.stringify({
    jsonrpc: '2.0',
    id: 1,
    method: 'tools/call',
    params: {
      name: 'search_customers',
      arguments: {
        limit: 10
      }
    }
  })
});

const data = await response.json();
console.log(data.result);
```

## Approach 2: Separate HTTP Service

Run the MCP server as a standalone HTTP service alongside your Rails app.

### Step 1: Start the HTTP Server

```bash
# In the ruby-quickbooks-mcp-server directory
PORT=3001 ./bin/quickbooks_mcp_http

# Or with stateless mode (recommended for multiple instances)
PORT=3001 STATELESS=true ./bin/quickbooks_mcp_http
```

### Step 2: Configure Rails to Use MCP Client

```ruby
# app/services/quickbooks_service.rb
class QuickbooksService
  def initialize
    @mcp_url = ENV['QUICKBOOKS_MCP_URL'] || 'http://localhost:3001'
  end

  def search_customers(criteria = {})
    call_tool('search_customers', criteria)
  end

  def create_customer(customer_data)
    call_tool('create_customer', customer: customer_data)
  end

  private

  def call_tool(tool_name, arguments)
    response = HTTParty.post(@mcp_url, {
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

    JSON.parse(response.body)
  end
end
```

### Step 3: Use in Controllers

```ruby
# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  def index
    qb_service = QuickbooksService.new
    @customers = qb_service.search_customers(limit: 50)
  end

  def create
    qb_service = QuickbooksService.new
    result = qb_service.create_customer(customer_params)

    if result['error']
      render json: { error: result['error'] }, status: :unprocessable_entity
    else
      render json: result['result']
    end
  end
end
```

### Step 4: Deploy with Docker

```dockerfile
# Dockerfile.quickbooks-mcp
FROM ruby:3.2

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3001

CMD ["./bin/quickbooks_mcp_http"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  rails:
    build: .
    ports:
      - "3000:3000"
    environment:
      QUICKBOOKS_MCP_URL: http://quickbooks-mcp:3001
    depends_on:
      - quickbooks-mcp

  quickbooks-mcp:
    build:
      context: ./ruby-quickbooks-mcp-server
      dockerfile: Dockerfile.quickbooks-mcp
    ports:
      - "3001:3001"
    environment:
      QUICKBOOKS_CLIENT_ID: ${QUICKBOOKS_CLIENT_ID}
      QUICKBOOKS_CLIENT_SECRET: ${QUICKBOOKS_CLIENT_SECRET}
      QUICKBOOKS_REFRESH_TOKEN: ${QUICKBOOKS_REFRESH_TOKEN}
      QUICKBOOKS_REALM_ID: ${QUICKBOOKS_REALM_ID}
      QUICKBOOKS_ENVIRONMENT: sandbox
      PORT: 3001
      STATELESS: true
```

## Approach 3: Background Stdio Process

Run the MCP server as a background process and communicate via stdio.

### Step 1: Create a Process Manager

```ruby
# app/services/quickbooks_mcp_process.rb
class QuickbooksMcpProcess
  def initialize
    @process = start_process
  end

  def call_tool(name, arguments)
    request = {
      jsonrpc: '2.0',
      id: SecureRandom.uuid,
      method: 'tools/call',
      params: {
        name: name,
        arguments: arguments
      }
    }

    @process.stdin.puts(request.to_json)
    response = @process.stdout.gets
    JSON.parse(response)
  end

  private

  def start_process
    mcp_path = Rails.root.join('vendor', 'quickbooks-mcp-server', 'bin', 'quickbooks_mcp_server')
    IO.popen([mcp_path.to_s], 'r+')
  end
end
```

**Note**: This approach is more complex and not recommended for production. Use Approach 1 or 2 instead.

## Multi-Tenant Support

If your Rails app is multi-tenant (multiple QuickBooks accounts), pass credentials explicitly per tenant:

```ruby
# app/models/organization.rb
class Organization < ApplicationRecord
  has_many :users

  # Columns: quickbooks_client_id, quickbooks_client_secret,
  #          quickbooks_refresh_token, quickbooks_realm_id, quickbooks_environment

  def quickbooks_server
    QuickbooksMCPServer.new(
      client_id: quickbooks_client_id,
      client_secret: quickbooks_client_secret,
      refresh_token: quickbooks_refresh_token,
      realm_id: quickbooks_realm_id,
      environment: quickbooks_environment || 'sandbox',
      server_context: {
        organization_id: id
      }
    )
  end
end

# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  def index
    qb = current_user.organization.quickbooks_server
    @customers = qb.search_customers(limit: 50)
  rescue QuickbooksMCPError => e
    flash[:error] = "QuickBooks error: #{e.message}"
    @customers = []
  end
end
```

### Service Object Pattern

```ruby
# app/services/quickbooks_service.rb
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
      ).update!(
        name: qb_customer['DisplayName'],
        email: qb_customer.dig('PrimaryEmailAddr', 'Address')
      )
    end
  end
end
```

## Testing in Rails

```ruby
# spec/requests/quickbooks_mcp_spec.rb
require 'rails_helper'

RSpec.describe 'QuickBooks MCP API', type: :request do
  let(:valid_headers) { { 'Content-Type' => 'application/json' } }

  describe 'POST /mcp/quickbooks' do
    context 'when listing tools' do
      let(:request_body) do
        {
          jsonrpc: '2.0',
          id: 1,
          method: 'tools/list'
        }.to_json
      end

      it 'returns list of available tools' do
        post '/mcp/quickbooks', params: request_body, headers: valid_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['result']['tools']).to be_an(Array)
        expect(json['result']['tools'].length).to be > 0
      end
    end

    context 'when calling a tool' do
      let(:request_body) do
        {
          jsonrpc: '2.0',
          id: 2,
          method: 'tools/call',
          params: {
            name: 'search_customers',
            arguments: { limit: 5 }
          }
        }.to_json
      end

      it 'calls the tool and returns results' do
        post '/mcp/quickbooks', params: request_body, headers: valid_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['result']).to be_present
      end
    end
  end
end
```

## Performance Considerations

### 1. Connection Pooling

For the separate HTTP service approach, use connection pooling:

```ruby
# config/initializers/quickbooks_mcp_client.rb
require 'connection_pool'

QUICKBOOKS_MCP_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  QuickbooksService.new
end

# Usage in controllers
def index
  QUICKBOOKS_MCP_POOL.with do |service|
    @customers = service.search_customers(limit: 50)
  end
end
```

### 2. Caching

Cache QuickBooks data to reduce API calls:

```ruby
# app/services/quickbooks_service.rb
def search_customers(criteria = {})
  cache_key = "qb_customers_#{Digest::MD5.hexdigest(criteria.to_json)}"

  Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
    call_tool('search_customers', criteria)
  end
end
```

### 3. Background Jobs

For long-running operations, use background jobs:

```ruby
# app/jobs/sync_quickbooks_job.rb
class SyncQuickbooksJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    service = QuickbooksService.new

    customers = service.search_customers(limit: 1000)
    # Process and save to database
  end
end
```

## Security Best Practices

1. **Always use HTTPS** in production
2. **Implement rate limiting** to prevent abuse
3. **Validate and sanitize** all inputs before passing to QuickBooks
4. **Use API keys** or OAuth for authentication
5. **Log all requests** for audit purposes
6. **Encrypt credentials** at rest and in transit
7. **Use separate credentials** per tenant in multi-tenant apps

## Monitoring and Logging

```ruby
# config/initializers/quickbooks_mcp.rb
MCP.configure do |config|
  config.exception_reporter = ->(exception, context) {
    # Send to your error tracking service
    Bugsnag.notify(exception) do |report|
      report.add_metadata(:quickbooks, context)
    end
  }

  config.instrumentation_callback = ->(data) {
    # Send to your metrics service
    StatsD.increment("quickbooks.tool_call", tags: ["tool:#{data[:tool_name]}"])
    StatsD.timing("quickbooks.duration", data[:duration])
  }
end
```

## Example: Full Rails Controller Integration

```ruby
# app/controllers/api/v1/quickbooks_controller.rb
module Api
  module V1
    class QuickbooksController < ApplicationController
      before_action :authenticate_user!
      before_action :check_quickbooks_connected

      def customers
        result = quickbooks_service.search_customers(
          criteria: search_params[:criteria],
          limit: params[:limit] || 50
        )

        render json: result
      end

      def create_customer
        result = quickbooks_service.create_customer(
          customer_params.to_h
        )

        if result['error']
          render json: { error: result['error'] }, status: :unprocessable_entity
        else
          render json: result['result'], status: :created
        end
      end

      def invoices
        result = quickbooks_service.search_invoices(
          criteria: search_params[:criteria],
          limit: params[:limit] || 50
        )

        render json: result
      end

      private

      def quickbooks_service
        @quickbooks_service ||= QuickbooksService.new(
          current_user.organization.quickbooks_credentials
        )
      end

      def check_quickbooks_connected
        unless current_user.organization.quickbooks_connected?
          render json: { error: 'QuickBooks not connected' }, status: :forbidden
        end
      end

      def customer_params
        params.require(:customer).permit(:DisplayName, :PrimaryEmailAddr, :PrimaryPhone)
      end

      def search_params
        params.permit(criteria: [:field, :value, :operator])
      end
    end
  end
end
```

## Recommended Approach

For most Rails applications, we recommend **Approach 1 (Direct Integration)** because:

- ✅ Simpler deployment (one app instead of two)
- ✅ Better performance (no network overhead)
- ✅ Easier to debug
- ✅ Can use Rails authentication and authorization
- ✅ Access to Rails models and business logic
- ✅ Simpler to test

Use **Approach 2 (Separate HTTP Service)** if:
- You need to scale the MCP server independently
- You're using multiple programming languages
- You want to share the MCP server across multiple applications
- You need strong isolation between services
