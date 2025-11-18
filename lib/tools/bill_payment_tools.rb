require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module BillPaymentTools
    def self.register(server, qb_client)
      # Create Bill Payment
      server.define_tool(
        name: 'create_bill_payment',
        description: 'Create a bill payment in QuickBooks Online.',
        input_schema: {
          properties: {
            bill_payment: {
              type: 'object',
              description: 'Bill payment data to create'
            }
          },
          required: ['bill_payment']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('BillPayment')

          bill_payment = ::Quickbooks::Model::BillPayment.new(args[:bill_payment])
          result = service.create(bill_payment)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill payment created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating bill payment: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Bill Payment
      server.define_tool(
        name: 'get_bill_payment',
        description: 'Get a bill payment by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Bill payment ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('BillPayment')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill payment found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching bill payment: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Bill Payment
      server.define_tool(
        name: 'update_bill_payment',
        description: 'Update a bill payment in QuickBooks Online.',
        input_schema: {
          properties: {
            bill_payment: {
              type: 'object',
              description: 'Bill payment data to update (must include Id and SyncToken)'
            }
          },
          required: ['bill_payment']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('BillPayment')

          bill_payment = ::Quickbooks::Model::BillPayment.new(args[:bill_payment])
          result = service.update(bill_payment, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill payment updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating bill payment: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Bill Payment
      server.define_tool(
        name: 'delete_bill_payment',
        description: 'Delete a bill payment in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Bill payment ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('BillPayment')

          bill_payment = service.fetch_by_id(args[:id])
          result = service.delete(bill_payment)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Bill payment deleted:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting bill payment: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Bill Payments
      server.define_tool(
        name: 'search_bill_payments',
        description: 'Search bill payments in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('BillPayment')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'BillPayment')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} bill payments:" },
            *results.map { |bp| { type: 'text', text: bp.attributes } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching bill payments: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
