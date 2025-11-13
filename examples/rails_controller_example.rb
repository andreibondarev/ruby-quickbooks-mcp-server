# Example Rails Controller for QuickBooks MCP Integration
#
# This is a simple example showing how to integrate the QuickBooks MCP server
# into a Rails application as a controller endpoint.
#
# Place this file in: app/controllers/quickbooks_mcp_controller.rb

class QuickbooksMcpController < ApplicationController
  # Skip CSRF for API endpoint
  skip_before_action :verify_authenticity_token

  # Optional: Add authentication
  # before_action :authenticate_user!
  # before_action :check_api_key

  def handle
    # Create server instance with context from current user/request
    server = QuickbooksMCPServer.new(
      server_context: {
        user_id: current_user&.id,
        request_id: request.uuid,
        # Add any other context you need
        # organization_id: current_user&.organization_id
      }
    )

    # Handle the JSON-RPC request
    response = server.handle_request(request.body.read)

    render json: response
  end

  private

  # Example API key authentication
  def check_api_key
    api_key = request.headers['X-API-Key']
    unless api_key == ENV['MCP_API_KEY']
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end

# Add this to config/routes.rb:
# post '/mcp/quickbooks', to: 'quickbooks_mcp#handle'

# Example usage from JavaScript:
#
# const response = await fetch('/mcp/quickbooks', {
#   method: 'POST',
#   headers: {
#     'Content-Type': 'application/json',
#     'X-API-Key': 'your-api-key'
#   },
#   body: JSON.stringify({
#     jsonrpc: '2.0',
#     id: 1,
#     method: 'tools/call',
#     params: {
#       name: 'search_customers',
#       arguments: {
#         limit: 10,
#         criteria: [
#           { field: 'Active', value: true, operator: '=' }
#         ]
#       }
#     }
#   })
# });
#
# const data = await response.json();
# console.log(data.result);
