# Deployment Options

This document outlines different ways to deploy and use the QuickBooks MCP server.

## Overview

The server supports two transport modes:

1. **Stdio Transport** - For MCP clients like Claude Desktop
2. **HTTP Transport (Streamable)** - For web applications and APIs

## Option 1: Stdio Mode (Claude Desktop)

### Use Case
- Claude Desktop integration
- Command-line tools
- MCP Inspector testing

### How to Run
```bash
./bin/quickbooks_mcp_server
```

### Architecture
```
┌─────────────────┐
│  Claude Desktop │
│                 │
│  (MCP Client)   │
└────────┬────────┘
         │ stdio
         │
┌────────▼────────┐
│   QBO MCP       │
│   Server        │
│   (Ruby)        │
└────────┬────────┘
         │
         │
┌────────▼────────┐
│  QuickBooks     │
│  API            │
└─────────────────┘
```

### Configuration
Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "quickbooks": {
      "command": "ruby",
      "args": ["/path/to/bin/quickbooks_mcp_server"],
      "env": {
        "QUICKBOOKS_CLIENT_ID": "...",
        "QUICKBOOKS_CLIENT_SECRET": "...",
        "QUICKBOOKS_REFRESH_TOKEN": "...",
        "QUICKBOOKS_REALM_ID": "...",
        "QUICKBOOKS_ENVIRONMENT": "sandbox"
      }
    }
  }
}
```

## Option 2: HTTP Mode (Standalone Service)

### Use Case
- Microservices architecture
- Multiple applications need QuickBooks access
- Language-agnostic integration
- Independent scaling

### How to Run
```bash
# Development
PORT=3001 ./bin/quickbooks_mcp_http

# Production (stateless)
PORT=3001 STATELESS=true ./bin/quickbooks_mcp_http
```

### Architecture
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Rails App  │    │  React App  │    │  Mobile App │
└──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │ HTTP             │ HTTP             │ HTTP
       └──────────────────┼──────────────────┘
                          │
                    ┌─────▼─────┐
                    │ Load      │
                    │ Balancer  │
                    └─────┬─────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼────┐       ┌────▼────┐      ┌────▼────┐
   │ QBO MCP │       │ QBO MCP │      │ QBO MCP │
   │ Server  │       │ Server  │      │ Server  │
   │ (Ruby)  │       │ (Ruby)  │      │ (Ruby)  │
   └────┬────┘       └────┬────┘      └────┬────┘
        └─────────────────┼─────────────────┘
                          │
                    ┌─────▼─────┐
                    │QuickBooks │
                    │    API    │
                    └───────────┘
```

### Docker Deployment
```dockerfile
# Dockerfile
FROM ruby:3.2-slim

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

EXPOSE 3001

CMD ["./bin/quickbooks_mcp_http"]
```

```bash
# Build
docker build -t quickbooks-mcp-server .

# Run
docker run -p 3001:3001 \
  -e QUICKBOOKS_CLIENT_ID="..." \
  -e QUICKBOOKS_CLIENT_SECRET="..." \
  -e QUICKBOOKS_REFRESH_TOKEN="..." \
  -e QUICKBOOKS_REALM_ID="..." \
  -e QUICKBOOKS_ENVIRONMENT="sandbox" \
  -e PORT=3001 \
  -e STATELESS=true \
  quickbooks-mcp-server
```

## Option 3: Embedded in Rails

### Use Case
- Rails monolith
- Single application needs QuickBooks
- Simplified deployment
- Direct access to Rails context

### How to Use
Integrate directly as a Rails controller:

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

### Architecture
```
┌────────────────────────────────┐
│        Rails Application       │
│  ┌──────────────────────────┐  │
│  │  QuickbooksMcpController │  │
│  └────────────┬─────────────┘  │
│               │                │
│  ┌────────────▼─────────────┐  │
│  │   QuickbooksMCPServer    │  │
│  │   (lib/quickbooks_mcp)   │  │
│  └────────────┬─────────────┘  │
│               │                │
└───────────────┼────────────────┘
                │
          ┌─────▼─────┐
          │QuickBooks │
          │    API    │
          └───────────┘
```

See [RAILS_INTEGRATION.md](RAILS_INTEGRATION.md) for complete guide.

## Stateless vs Stateful Mode

### Stateless Mode (`STATELESS=true`)
- ✅ Can scale horizontally
- ✅ No session state
- ✅ Works behind load balancers
- ✅ Recommended for production
- ❌ No SSE notifications

### Stateful Mode (default)
- ✅ Supports SSE notifications
- ✅ Session-based features
- ❌ Harder to scale
- ❌ Needs sticky sessions
- Use for: Single instance or development

## Production Deployment Recommendations

### 1. Environment Variables
Use a secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.):

```bash
# Don't do this in production
export QUICKBOOKS_CLIENT_SECRET="my-secret"

# Do this instead
export QUICKBOOKS_CLIENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id quickbooks/client_secret \
  --query SecretString \
  --output text)
```

### 2. Health Checks
Add a health check endpoint:

```ruby
# In quickbooks_mcp_server.rb
def self.health_check
  {
    status: 'healthy',
    version: '1.0.0',
    timestamp: Time.now.iso8601
  }
end
```

### 3. Monitoring
Configure instrumentation:

```ruby
MCP.configure do |config|
  config.instrumentation_callback = ->(data) {
    StatsD.increment('quickbooks.tool_call')
    StatsD.timing('quickbooks.duration', data[:duration])
  }
end
```

### 4. Logging
Use structured logging:

```ruby
config.exception_reporter = ->(exception, context) {
  logger.error(
    message: 'QuickBooks MCP error',
    exception: exception.message,
    context: context,
    backtrace: exception.backtrace
  )
}
```

### 5. Rate Limiting
Implement rate limiting (especially for multi-tenant):

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  throttle('quickbooks/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path == '/mcp/quickbooks'
  end

  throttle('quickbooks/user', limit: 50, period: 1.minute) do |req|
    req.env['warden'].user&.id if req.path == '/mcp/quickbooks'
  end
end
```

## Scaling Considerations

### Horizontal Scaling (HTTP Stateless)
```yaml
# kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quickbooks-mcp
spec:
  replicas: 3  # Scale to 3 instances
  selector:
    matchLabels:
      app: quickbooks-mcp
  template:
    metadata:
      labels:
        app: quickbooks-mcp
    spec:
      containers:
      - name: quickbooks-mcp
        image: quickbooks-mcp:latest
        env:
        - name: STATELESS
          value: "true"
        - name: PORT
          value: "3001"
        ports:
        - containerPort: 3001
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: quickbooks-mcp
spec:
  selector:
    app: quickbooks-mcp
  ports:
  - port: 80
    targetPort: 3001
  type: LoadBalancer
```

### Connection Pooling
For the QuickBooks API client:

```ruby
# Use a connection pool for OAuth client
QUICKBOOKS_POOL = ConnectionPool.new(size: 10, timeout: 5) do
  QuickbooksClient.new(...)
end

# In your tools
QUICKBOOKS_POOL.with do |qb_client|
  service = qb_client.service('Customer')
  service.create(customer)
end
```

## Performance Benchmarks

Expected performance (on modest hardware):

| Mode | Requests/sec | Latency (p95) | Memory |
|------|--------------|---------------|--------|
| Stdio | N/A | ~100ms | ~50MB |
| HTTP Stateless | ~500 | ~150ms | ~75MB |
| HTTP Stateful | ~300 | ~200ms | ~100MB |
| Rails Embedded | ~400 | ~180ms | ~150MB |

*Note: Actual performance depends on QuickBooks API response times*

## Security Checklist

- [ ] Use HTTPS in production
- [ ] Implement authentication (API keys, OAuth)
- [ ] Rate limit requests
- [ ] Validate all inputs
- [ ] Encrypt credentials at rest
- [ ] Use separate credentials per tenant
- [ ] Enable audit logging
- [ ] Set up monitoring and alerts
- [ ] Regular security updates
- [ ] Use secrets manager (not environment variables in production)

## Troubleshooting

### Issue: "Connection refused" on HTTP mode
**Solution**: Check that port is available and not blocked by firewall

```bash
lsof -i :3001  # Check if port is in use
```

### Issue: "QuickBooks not authenticated"
**Solution**: Verify environment variables are set correctly

```bash
# Test authentication
ruby -r './lib/quickbooks_client' -e "
  client = QuickbooksClient.new(
    client_id: ENV['QUICKBOOKS_CLIENT_ID'],
    client_secret: ENV['QUICKBOOKS_CLIENT_SECRET'],
    refresh_token: ENV['QUICKBOOKS_REFRESH_TOKEN'],
    realm_id: ENV['QUICKBOOKS_REALM_ID'],
    environment: 'sandbox'
  )
  client.authenticate
  puts 'Authentication successful!'
"
```

### Issue: High memory usage
**Solution**: Enable stateless mode and implement connection pooling

```bash
STATELESS=true PORT=3001 ./bin/quickbooks_mcp_http
```

### Issue: Slow response times
**Solution**: Implement caching for frequently accessed data

```ruby
# Cache customer lookups for 5 minutes
Rails.cache.fetch("qb_customer_#{id}", expires_in: 5.minutes) do
  qb_service.get_customer(id)
end
```

## Next Steps

1. Choose your deployment mode based on your use case
2. Follow the appropriate setup guide
3. Configure monitoring and logging
4. Set up health checks
5. Implement rate limiting
6. Deploy to staging first
7. Load test before production
8. Set up alerts and monitoring dashboards
