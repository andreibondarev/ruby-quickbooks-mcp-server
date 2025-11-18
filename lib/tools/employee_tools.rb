require_relative '../helpers/format_error'
require_relative '../helpers/search_criteria_builder'

module Tools
  module EmployeeTools
    def self.register(server, qb_client)
      # Create Employee
      server.define_tool(
        name: 'create_employee',
        description: 'Create an employee in QuickBooks Online.',
        input_schema: {
          properties: {
            employee: {
              type: 'object',
              description: 'Employee data to create'
            }
          },
          required: ['employee']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Employee')

          employee = ::Quickbooks::Model::Employee.new(args[:employee])
          result = service.create(employee)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Employee created:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error creating employee: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Get Employee
      server.define_tool(
        name: 'get_employee',
        description: 'Get an employee by ID from QuickBooks Online.',
        input_schema: {
          properties: {
            id: {
              type: 'string',
              description: 'Employee ID'
            }
          },
          required: ['id']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Employee')

          result = service.fetch_by_id(args[:id])

          MCP::Tool::Response.new([
            { type: 'text', text: 'Employee found:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error fetching employee: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Update Employee
      server.define_tool(
        name: 'update_employee',
        description: 'Update an employee in QuickBooks Online.',
        input_schema: {
          properties: {
            employee: {
              type: 'object',
              description: 'Employee data to update (must include Id and SyncToken)'
            }
          },
          required: ['employee']
        }
      ) do |**kwargs|
        args = kwargs.except(:server_context)

        begin
          qb_client.authenticate
          service = qb_client.service('Employee')

          employee = ::Quickbooks::Model::Employee.new(args[:employee])
          result = service.update(employee, sparse: true)

          MCP::Tool::Response.new([
            { type: 'text', text: 'Employee updated:' },
            { type: 'text', text: result.attributes }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error updating employee: #{Helpers.format_error(e)}" }
          ])
        end
      end

      # Search Employees
      server.define_tool(
        name: 'search_employees',
        description: 'Search employees in QuickBooks Online that match given criteria.',
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
          service = qb_client.service('Employee')

          query_result = Helpers::SearchCriteriaBuilder.build(args, 'Employee')
          results = if query_result[:query]
            service.query(query_result[:query], **query_result[:options])
          else
            service.all
          end

          MCP::Tool::Response.new([
            { type: 'text', text: "Found #{results.count} employees:" },
            *results.map { |e| { type: 'text', text: e.attributes } }
          ])
        rescue StandardError => e
          MCP::Tool::Response.new([
            { type: 'text', text: "Error searching employees: #{Helpers.format_error(e)}" }
          ])
        end
      end
    end
  end
end
