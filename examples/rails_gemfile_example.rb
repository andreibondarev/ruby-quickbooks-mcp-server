# Example Gemfile for your Rails app
# This shows how to include the QuickBooks MCP server as a local gem

source 'https://rubygems.org'

gem 'rails', '~> 7.0'

# ... your other gems ...

# Option 1: Local development (recommended)
gem 'quickbooks_mcp', path: '../ruby-quickbooks-mcp-server'

# Option 2: From git repository
# gem 'quickbooks_mcp', git: 'https://github.com/yourusername/ruby-quickbooks-mcp-server.git'

# Option 3: From git with specific version
# gem 'quickbooks_mcp', git: 'https://github.com/yourusername/ruby-quickbooks-mcp-server.git', tag: 'v1.0.0'

# Then run:
# bundle install

# Usage in your Rails app:
#
# # app/controllers/api/quickbooks_controller.rb
# class Api::QuickbooksController < ApplicationController
#   def customers
#     server = QuickbooksMCPServer.new(
#       server_context: { user_id: current_user.id }
#     )
#
#     # Call a tool directly or handle full JSON-RPC request
#     request_json = {
#       jsonrpc: '2.0',
#       id: 1,
#       method: 'tools/call',
#       params: {
#         name: 'search_customers',
#         arguments: { limit: 50 }
#       }
#     }.to_json
#
#     response = server.handle_request(request_json)
#     render json: response
#   end
# end
