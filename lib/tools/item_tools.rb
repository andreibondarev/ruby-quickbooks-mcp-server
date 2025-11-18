require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module ItemTools
    def self.register(server, qb_client)
      # Create Item
      server.define_tool(
        name: 'create_item',
        description: 'Create an item in QuickBooks Online.',
        input_schema: {
          properties: {
            item: {
              type: 'object',
              description: 'Item data to create'
            }
          },
          required: ['item']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Item')

          item = ::Quickbooks::Model::Item.new(args[:item])
          result = service.create(item)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Item created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating item: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Read Item
      server.define_tool(
        name: 'read_item',
        description: 'Read an item by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Item ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Item')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Item found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error reading item: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Item
      server.define_tool(
        name: 'update_item',
        description: 'Update an item in QuickBooks Online.',
        input_schema: {
          properties: {
            item: {
              type: 'object',
              description: 'Item data to update (must include id and sync_token)'
            }
          },
          required: ['item']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Item')

          item = ::Quickbooks::Model::Item.new(args[:item])
          result = service.update(item, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Item updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating item: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Items
      server.define_tool(
        name: 'search_items',
        description: 'Search items in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Item')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'Item')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} items:" },
            *results.map { |i| { type: 'text', text: JSON.pretty_generate(i.as_json) } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching items: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
