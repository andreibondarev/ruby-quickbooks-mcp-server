require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module EstimateTools
    def self.register(server, qb_client)
      # Create Estimate
      server.define_tool(
        name: 'create_estimate',
        description: 'Create an estimate in QuickBooks Online.',
        input_schema: {
          properties: {
            estimate: {
              type: 'object',
              description: 'Estimate data to create'
            }
          },
          required: ['estimate']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Estimate')

          estimate = ::Quickbooks::Model::Estimate.new(args[:estimate])
          result = service.create(estimate)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Estimate created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating estimate: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Estimate
      server.define_tool(
        name: 'get_estimate',
        description: 'Get an estimate by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Estimate ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Estimate')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Estimate found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching estimate: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Estimate
      server.define_tool(
        name: 'update_estimate',
        description: 'Update an estimate in QuickBooks Online.',
        input_schema: {
          properties: {
            estimate: {
              type: 'object',
              description: 'Estimate data to update (must include Id and SyncToken)'
            }
          },
          required: ['estimate']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Estimate')

          estimate = ::Quickbooks::Model::Estimate.new(args[:estimate])
          result = service.update(estimate)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Estimate updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating estimate: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Estimate
      server.define_tool(
        name: 'delete_estimate',
        description: 'Delete an estimate in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Estimate ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Estimate')

          estimate = service.fetch_by_id(args[:id])
          result = service.delete(estimate)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Estimate deleted:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting estimate: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Estimates
      server.define_tool(
        name: 'search_estimates',
        description: 'Search estimates in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Estimate')

          query = Helpers::SearchCriteriaBuilder.build(args)
          results = if query && !query.empty?
            service.query(query)
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} estimates:" },
            *results.map { |e| { type: 'text', text: e.attributes } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching estimates: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
