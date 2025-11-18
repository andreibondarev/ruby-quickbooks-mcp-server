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
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          vendor = ::Quickbooks::Model::Vendor.new(args[:vendor])
          result = service.create(vendor)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor created:' },
            { type: 'text', text: result.attributes }
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
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor found:' },
            { type: 'text', text: result.attributes }
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
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          vendor = ::Quickbooks::Model::Vendor.new(args[:vendor])
          result = service.update(vendor, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor updated:' },
            { type: 'text', text: result.attributes }
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
        args = kwargs.except(:server_context)
        args.delete(:server_context)
        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          vendor = service.fetch_by_id(args[:id])
          result = service.delete(vendor)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Vendor deleted:' },
            { type: 'text', text: result.attributes }
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
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Vendor')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'Vendor')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} vendors:" },
            *results.map { |v| { type: 'text', text: v.attributes } }
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
