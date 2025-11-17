require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'
require "pry-byebug"

module Tools
  module CustomerTools
    def self.register(server, qb_client)
      # Create Customer
      server.define_tool(
        name: 'create_customer',
        description: 'Create a customer in QuickBooks Online.',
        input_schema: {
          properties: {
            customer: {
              type: 'object',
              description: 'Customer data to create'
            }
          },
          required: ['customer']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Customer')

          customer = ::Quickbooks::Model::Customer.new
          customer.from_json(args[:customer].to_json)
          result = service.create(customer)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Customer created:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating customer: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Customer
      server.define_tool(
        name: 'get_customer',
        description: 'Get a customer by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Customer ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Customer')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Customer found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching customer: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Customer
      server.define_tool(
        name: 'update_customer',
        description: 'Update a customer in QuickBooks Online.',
        input_schema: {
          properties: {
            customer: {
              type: 'object',
              description: 'Customer data to update (must include Id and SyncToken)'
            }
          },
          required: ['customer']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Customer')

          customer = ::Quickbooks::Model::Customer.new(args[:customer])
          result = service.update(customer)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Customer updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating customer: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Customer
      server.define_tool(
        name: 'delete_customer',
        description: 'Delete a customer in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Customer ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Customer')

          customer = service.fetch_by_id(args[:id])
          result = service.delete(customer)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Customer deleted (deactivated):' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting customer: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Customers
      server.define_tool(
        name: 'search_customers',
        description: 'Search customers in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Customer')

          query = Helpers::SearchCriteriaBuilder.build(args)
          results = if query && !query.empty?
            service.query(query)
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} customers:" },
            *results.map { |c| { type: 'text', text: JSON.pretty_generate(c.as_json) } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching customers: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
