require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module PurchaseTools
    def self.register(server, qb_client)
      # Create Purchase
      server.define_tool(
        name: 'create_purchase',
        description: 'Create a purchase in QuickBooks Online.',
        input_schema: {
          properties: {
            purchase: {
              type: 'object',
              description: 'Purchase data to create'
            }
          },
          required: ['purchase']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Purchase')

          purchase = Quickbooks::Model::Purchase.new(args[:purchase])
          result = service.create(purchase)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Purchase created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating purchase: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Purchase
      server.define_tool(
        name: 'get_purchase',
        description: 'Get a purchase by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Purchase ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Purchase')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Purchase found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching purchase: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Purchase
      server.define_tool(
        name: 'update_purchase',
        description: 'Update a purchase in QuickBooks Online.',
        input_schema: {
          properties: {
            purchase: {
              type: 'object',
              description: 'Purchase data to update (must include Id and SyncToken)'
            }
          },
          required: ['purchase']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Purchase')

          purchase = Quickbooks::Model::Purchase.new(args[:purchase])
          result = service.update(purchase)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Purchase updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating purchase: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Purchase
      server.define_tool(
        name: 'delete_purchase',
        description: 'Delete a purchase in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Purchase ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Purchase')

          purchase = service.fetch_by_id(args[:id])
          result = service.delete(purchase)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Purchase deleted:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting purchase: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Purchases
      server.define_tool(
        name: 'search_purchases',
        description: 'Search purchases in QuickBooks Online that match given criteria.',
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
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Purchase')

          query = Helpers::SearchCriteriaBuilder.build(args)
          results = if query && !query.empty?
            service.query(query)
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} purchases:" },
            *results.map { |p| { type: 'text', text: p.attributes } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching purchases: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
