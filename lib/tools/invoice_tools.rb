require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module InvoiceTools
    def self.register(server, qb_client)
      # Create Invoice
      server.define_tool(
        name: 'create_invoice',
        description: 'Create an invoice in QuickBooks Online.',
        input_schema: {
          properties: {
            invoice: {
              type: 'object',
              description: 'Invoice data to create'
            }
          },
          required: ['invoice']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Invoice')

          invoice = ::Quickbooks::Model::Invoice.new(args[:invoice])
          result = service.create(invoice)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Invoice created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating invoice: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Read Invoice
      server.define_tool(
        name: 'read_invoice',
        description: 'Read an invoice by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Invoice ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Invoice')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Invoice found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error reading invoice: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Invoice
      server.define_tool(
        name: 'update_invoice',
        description: 'Update an invoice in QuickBooks Online.',
        input_schema: {
          properties: {
            invoice: {
              type: 'object',
              description: 'Invoice data to update (must include Id and SyncToken)'
            }
          },
          required: ['invoice']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Invoice')

          invoice = ::Quickbooks::Model::Invoice.new(args[:invoice])
          result = service.update(invoice, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Invoice updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating invoice: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Invoices
      server.define_tool(
        name: 'search_invoices',
        description: 'Search invoices in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Invoice')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'Invoice')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} invoices:" },
            *results.map { |i| { type: 'text', text: i.attributes } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching invoices: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
