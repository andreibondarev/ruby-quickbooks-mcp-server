require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module BillTools
    def self.register(server, qb_client)
      # Create Bill
      server.define_tool(
        name: 'create_bill',
        description: 'Create a bill in QuickBooks Online.',
        input_schema: {
          properties: {
            bill: {
              type: 'object',
              description: 'Bill data to create'
            }
          },
          required: ['bill']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Bill')

          bill = Quickbooks::Model::Bill.new
          bill.from_json(args[:bill].to_json)
          result = service.create(bill)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill created:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating bill: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Bill
      server.define_tool(
        name: 'get_bill',
        description: 'Get a bill by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Bill ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Bill')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill found:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching bill: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Bill
      server.define_tool(
        name: 'update_bill',
        description: 'Update a bill in QuickBooks Online.',
        input_schema: {
          properties: {
            bill: {
              type: 'object',
              description: 'Bill data to update (must include Id and SyncToken)'
            }
          },
          required: ['bill']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Bill')

          bill = Quickbooks::Model::Bill.new
          bill.from_json(args[:bill].to_json)
          result = service.update(bill)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill updated:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating bill: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Bill
      server.define_tool(
        name: 'delete_bill',
        description: 'Delete a bill in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Bill ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Bill')

          bill = service.fetch_by_id(args[:id])
          result = service.delete(bill)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill deleted:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting bill: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Bills
      server.define_tool(
        name: 'search_bills',
        description: 'Search bills in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Bill')

          query = Helpers::SearchCriteriaBuilder.build(args)
          results = if query && !query.empty?
            service.query(query)
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} bills:" },
            *results.map { |b| { type: 'text', text: JSON.pretty_generate(b.as_json) } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching bills: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
