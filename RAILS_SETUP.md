# How to Include QuickBooks MCP in Your Rails App

You have several options for including this library in your Rails application.

## Option 1: Local Path Gem (Recommended for Development)

If the QuickBooks MCP server is in the same directory structure as your Rails app:

```ruby
# In your Rails app's Gemfile
gem 'quickbooks_mcp', path: '../ruby-quickbooks-mcp-server'
```

Then run:
```bash
bundle install
```

### Project Structure
```
/your-projects/
  ├── my-rails-app/
  │   ├── Gemfile  # references ../ruby-quickbooks-mcp-server
  │   └── app/
  └── ruby-quickbooks-mcp-server/
      ├── lib/
      └── Gemfile
```

## Option 2: Git Repository (Recommended for Production)

Reference it directly from Git:

```ruby
# In your Rails app's Gemfile
gem 'quickbooks_mcp', git: 'https://github.com/yourusername/ruby-quickbooks-mcp-server.git'

# Or with a specific branch/tag
gem 'quickbooks_mcp', git: 'https://github.com/yourusername/ruby-quickbooks-mcp-server.git', tag: 'v1.0.0'
```

### Setup for Git Gem
You need to add a `.gemspec` file to make it a proper gem:

```ruby
# quickbooks_mcp.gemspec
Gem::Specification.new do |spec|
  spec.name          = "quickbooks_mcp"
  spec.version       = "1.0.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "QuickBooks MCP Server"
  spec.description   = "Model Context Protocol server for QuickBooks Online integration"
  spec.homepage      = "https://github.com/yourusername/ruby-quickbooks-mcp-server"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "mcp", git: "https://github.com/modelcontextprotocol/ruby-sdk.git", branch: "main"
  spec.add_dependency "quickbooks-ruby", "~> 2.0"
  spec.add_dependency "dotenv", "~> 3.1"
  spec.add_dependency "oauth2", "~> 1.4"
  spec.add_dependency "puma", "~> 6.5"
  spec.add_dependency "rackup", "~> 2.2"
end
```

## Option 3: Copy lib Directory (Simple)

Just copy the `lib` directory into your Rails app:

```bash
cp -r ruby-quickbooks-mcp-server/lib/* my-rails-app/lib/quickbooks_mcp/
```

Then in Rails:
```ruby
# config/application.rb
config.autoload_paths += %W(#{config.root}/lib/quickbooks_mcp)

# Or in an initializer
# config/initializers/quickbooks_mcp.rb
require_relative '../../lib/quickbooks_mcp/quickbooks_mcp_server'
```

**Cons**: Have to manually manage updates and dependencies.

## Option 4: Build as a Gem (For Distribution)

If you want to publish to RubyGems or use in multiple projects:

### Step 1: Create gemspec
Create `quickbooks_mcp.gemspec` (see Option 2)

### Step 2: Build the gem
```bash
gem build quickbooks_mcp.gemspec
```

### Step 3: Install locally
```bash
gem install ./quickbooks_mcp-1.0.0.gem
```

### Step 4: Use in Rails
```ruby
# Gemfile
gem 'quickbooks_mcp', '~> 1.0.0'
```

## Option 5: Monorepo (Engines)

Make it a Rails Engine within your monorepo:

```ruby
# lib/quickbooks_mcp/engine.rb
module QuickbooksMcp
  class Engine < ::Rails::Engine
    isolate_namespace QuickbooksMcp
  end
end

# In your Rails app's Gemfile
gem 'quickbooks_mcp', path: 'engines/quickbooks_mcp'
```

---

## Recommended Approach by Use Case

### For a Single Rails App (Development)
✅ **Option 1: Local Path Gem**
- Simple to set up
- Easy to develop and test
- Changes reflected immediately

### For Multiple Rails Apps (Production)
✅ **Option 2: Git Repository**
- Centralized source of truth
- Easy version management
- Can reference specific versions/tags

### For Quick Prototyping
✅ **Option 3: Copy lib Directory**
- Fastest to get started
- No gem management overhead

### For Public Distribution
✅ **Option 4: Build as Gem**
- Professional distribution
- Semantic versioning
- Easy for others to use

---

## Usage in Rails After Installation

### Direct Controller Integration

```ruby
# app/controllers/quickbooks_mcp_controller.rb
class QuickbooksMcpController < ApplicationController
  skip_before_action :verify_authenticity_token

  def handle
    server = QuickbooksMCPServer.new(
      server_context: {
        user_id: current_user&.id,
        organization_id: current_organization&.id
      }
    )

    render json: server.handle_request(request.body.read)
  end
end
```

### Service Object Pattern

```ruby
# app/services/quickbooks_service.rb
class QuickbooksService
  def initialize(user)
    @user = user
    @server = QuickbooksMCPServer.new(
      server_context: { user_id: user.id }
    )
  end

  def search_customers(criteria = {})
    # Call MCP tool directly or use handle_request
  end
end
```

### Background Jobs

```ruby
# app/jobs/sync_quickbooks_job.rb
class SyncQuickbooksJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    service = QuickbooksService.new(user)
    service.sync_all_data
  end
end
```

---

## Quick Start (Recommended Path)

1. **Add gemspec file** to ruby-quickbooks-mcp-server:

```bash
cd ruby-quickbooks-mcp-server
cat > quickbooks_mcp.gemspec << 'EOF'
Gem::Specification.new do |spec|
  spec.name          = "quickbooks_mcp"
  spec.version       = "1.0.0"
  spec.authors       = ["Your Name"]
  spec.summary       = "QuickBooks MCP Server"
  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "mcp"
  spec.add_dependency "quickbooks-ruby", "~> 1.0"
  spec.add_dependency "dotenv", "~> 3.1"
  spec.add_dependency "oauth2", "~> 1.4"
  spec.add_dependency "puma", "~> 6.5"
end
EOF
```

2. **In your Rails Gemfile**:

```ruby
# Gemfile
gem 'quickbooks_mcp', path: '../ruby-quickbooks-mcp-server'
# Or from git:
# gem 'quickbooks_mcp', git: 'https://github.com/yourusername/ruby-quickbooks-mcp-server.git'
```

3. **Install**:

```bash
bundle install
```

4. **Use it**:

```ruby
# anywhere in your Rails app
server = QuickbooksMCPServer.new
result = server.handle_request(mcp_json_request)
```

That's it! No complex gem building required for local development.
