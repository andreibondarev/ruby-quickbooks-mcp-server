require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module VendorTools
    def self.register(server, qb_client)
      # Create Vendor
      server.define_tool(
        name: 'create_vendor',
        description: 'Create a vendor in QuickBooks Online.',
        input_schema: {
          properties: {
            vendor: {
              type: 'object',
              description: 'Vendor data to create'
            }
          },
          required: ['vendor']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          vendor = Quickbooks::Model::Vendor.new
          vendor.from_json(args[:vendor].to_json)
          result = service.create(vendor)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor created:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating vendor: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Vendor
      server.define_tool(
        name: 'get_vendor',
        description: 'Get a vendor by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Vendor ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor found:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching vendor: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Vendor
      server.define_tool(
        name: 'update_vendor',
        description: 'Update a vendor in QuickBooks Online.',
        input_schema: {
          properties: {
            vendor: {
              type: 'object',
              description: 'Vendor data to update (must include Id and SyncToken)'
            }
          },
          required: ['vendor']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          vendor = Quickbooks::Model::Vendor.new
          vendor.from_json(args[:vendor].to_json)
          result = service.update(vendor)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor updated:' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating vendor: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Vendor
      server.define_tool(
        name: 'delete_vendor',
        description: 'Delete a vendor in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Vendor ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs[:args] || kwargs
        server_context = kwargs[:server_context] || {}
        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          vendor = service.fetch_by_id(args[:id])
          vendor.active = false
          result = service.update(vendor)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor deleted (deactivated):' },
            { type: 'text', text: JSON.pretty_generate(result.as_json) }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting vendor: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Vendors
      server.define_tool(
        name: 'search_vendors',
        description: 'Search vendors in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Vendor')

          query = Helpers::SearchCriteriaBuilder.build(args)
          results = if query && !query.empty?
            service.query(query)
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} vendors:" },
            *results.map { |v| { type: 'text', text: JSON.pretty_generate(v.as_json) } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching vendors: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
