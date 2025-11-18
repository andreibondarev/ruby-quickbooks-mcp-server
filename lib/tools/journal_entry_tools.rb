require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module JournalEntryTools
    def self.register(server, qb_client)
      # Create Journal Entry
      server.define_tool(
        name: 'create_journal_entry',
        description: 'Create a journal entry in QuickBooks Online.',
        input_schema: {
          properties: {
            journal_entry: {
              type: 'object',
              description: 'Journal entry data to create'
            }
          },
          required: ['journal_entry']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('JournalEntry')

          journal_entry = ::Quickbooks::Model::JournalEntry.new(args[:journal_entry])
          result = service.create(journal_entry)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Journal entry created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating journal entry: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Journal Entry
      server.define_tool(
        name: 'get_journal_entry',
        description: 'Get a journal entry by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Journal entry ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('JournalEntry')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Journal entry found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching journal entry: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Journal Entry
      server.define_tool(
        name: 'update_journal_entry',
        description: 'Update a journal entry in QuickBooks Online.',
        input_schema: {
          properties: {
            journal_entry: {
              type: 'object',
              description: 'Journal entry data to update (must include id and sync_token)'
            }
          },
          required: ['journal_entry']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('JournalEntry')

          journal_entry = ::Quickbooks::Model::JournalEntry.new(args[:journal_entry])
          result = service.update(journal_entry, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Journal entry updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating journal entry: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Delete Journal Entry
      server.define_tool(
        name: 'delete_journal_entry',
        description: 'Delete a journal entry in QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Journal entry ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('JournalEntry')

          journal_entry = service.fetch_by_id(args[:id])
          result = service.delete(journal_entry)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Journal entry deleted:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error deleting journal entry: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Journal Entries
      server.define_tool(
        name: 'search_journal_entries',
        description: 'Search journal entries in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('JournalEntry')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'JournalEntry')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} journal entries:" },
            *results.map { |je| { type: 'text', text: je.attributes } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching journal entries: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
