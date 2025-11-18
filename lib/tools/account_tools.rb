require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module AccountTools
    def self.register(server, qb_client)
      # Create Account
      server.define_tool(
        name: 'create_account',
        description: 'Create an account in QuickBooks Online.',
        input_schema: {
          properties: {
            account: {
              type: 'object',
              description: 'Account data to create'
            }
          },
          required: ['account']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Account')

          account = ::Quickbooks::Model::Account.new(args[:account])
          result = service.create(account)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Account created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating account: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Account
      server.define_tool(
        name: 'update_account',
        description: 'Update an account in QuickBooks Online.',
        input_schema: {
          properties: {
            account: {
              type: 'object',
              description: 'Account data to update (must include id and sync_token)'
            }
          },
          required: ['account']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Account')

          account = Quickbooks::Model::Account.new(args[:account])
          result = service.update(account, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Account updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating account: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Accounts
      server.define_tool(
        name: 'search_accounts',
        description: 'Search accounts in QuickBooks Online that match given criteria.',
        input_schema: {
          properties: {
            criteria: {
              type: 'array',
              description: 'Filters to apply',
              items: {
                type: 'object',
                properties: {
                  field: { type: 'string' },
                  value: { type: ['string', 'boolean', 'number'] },
                  operator: { type: 'string' }
                }
              }
            },
            limit: { type: 'number' },
            offset: { type: 'number' },
            asc: { type: 'string' },
            desc: { type: 'string' }
          }
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Account')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'Account')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} accounts:" },
            *results.map { |a| { type: 'text', text: JSON.pretty_generate(a.as_json) } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching accounts: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
