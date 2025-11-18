module Helpers
  # Builds QuickBooks query strings from various input formats
  class SearchCriteriaBuilder
    def self.build(criteria, entity_name)
      return { query: nil, options: {} } if criteria.nil? || criteria.empty?

      if criteria.is_a?(Hash)
        build_from_hash(criteria, entity_name)
      elsif criteria.is_a?(Array)
        build_from_array(criteria, entity_name)
      else
        { query: nil, options: {} }
      end
    end

    def self.build_from_hash(hash, entity_name)
      # Extract special keys
      filters = hash[:filters] || hash['filters'] || []
      criteria_array = hash[:criteria] || hash['criteria'] || []
      asc = hash[:asc] || hash['asc']
      desc = hash[:desc] || hash['desc']
      limit = hash[:limit] || hash['limit']
      offset = hash[:offset] || hash['offset']

      # Build WHERE clause from filters or direct key-value pairs
      where_parts = []

      # Handle criteria array (from search tools)
      if criteria_array.any?
        criteria_array.each do |filter|
          field = filter[:field] || filter['field']
          value = filter[:value] || filter['value']
          operator = filter[:operator] || filter['operator'] || '='

          where_parts << build_condition(field, value, operator)
        end
      elsif filters.any?
        filters.each do |filter|
          field = filter[:field] || filter['field']
          value = filter[:value] || filter['value']
          operator = filter[:operator] || filter['operator'] || '='

          where_parts << build_condition(field, value, operator)
        end
      else
        # Treat other hash keys as simple equality filters
        hash.each do |key, value|
          next if [:filters, :criteria, :asc, :desc, :limit, :offset, 'filters', 'criteria', 'asc', 'desc', 'limit', 'offset'].include?(key)
          where_parts << build_condition(key.to_s, value, '=')
        end
      end

      # Build query parts
      query_parts = ["SELECT * FROM #{entity_name}"]
      query_parts << "WHERE #{where_parts.join(' AND ')}" if where_parts.any?
      query_parts << "ORDERBY #{asc} ASC" if asc
      query_parts << "ORDERBY #{desc} DESC" if desc

      # Build options hash for pagination
      options = {}
      options[:per_page] = limit if limit

      # Convert offset to page number
      if offset && limit
        options[:page] = (offset / limit) + 1
      elsif offset
        # Default per_page is 20 in the gem
        options[:page] = (offset / 20) + 1
      end

      { query: query_parts.join(' '), options: options }
    end

    def self.build_from_array(array, entity_name)
      # Array of filter objects
      where_parts = []
      order_by = nil
      limit = nil
      offset = nil

      array.each do |item|
        if item.is_a?(Hash)
          field = item[:field] || item['field']
          value = item[:value] || item['value']
          operator = item[:operator] || item['operator']

          case field&.to_s&.downcase
          when 'asc'
            order_by = "ORDERBY #{value} ASC"
          when 'desc'
            order_by = "ORDERBY #{value} DESC"
          when 'limit'
            limit = value
          when 'offset'
            offset = value
          else
            where_parts << build_condition(field, value, operator || '=') if field
          end
        end
      end

      query_parts = ["SELECT * FROM #{entity_name}"]
      query_parts << "WHERE #{where_parts.join(' AND ')}" if where_parts.any?
      query_parts << order_by if order_by

      # Build options hash for pagination
      options = {}
      options[:per_page] = limit if limit

      # Convert offset to page number
      if offset && limit
        options[:page] = (offset / limit) + 1
      elsif offset
        # Default per_page is 20 in the gem
        options[:page] = (offset / 20) + 1
      end

      { query: query_parts.join(' '), options: options }
    end

    def self.build_condition(field, value, operator)
      formatted_value = format_value(value)
      "#{field} #{operator} #{formatted_value}"
    end

    def self.format_value(value)
      case value
      when String
        "'#{value.gsub("'", "\\\\'")}'"
      when true, false
        value.to_s
      when nil
        'NULL'
      when Numeric
        value.to_s
      else
        "'#{value}'"
      end
    end
  end
end
