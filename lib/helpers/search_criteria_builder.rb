module Helpers
  # Builds QuickBooks query strings from various input formats
  class SearchCriteriaBuilder
    def self.build(criteria)
      return nil if criteria.nil? || criteria.empty?

      if criteria.is_a?(Hash)
        build_from_hash(criteria)
      elsif criteria.is_a?(Array)
        build_from_array(criteria)
      else
        nil
      end
    end

    def self.build_from_hash(hash)
      # Extract special keys
      filters = hash[:filters] || hash['filters'] || []
      asc = hash[:asc] || hash['asc']
      desc = hash[:desc] || hash['desc']
      limit = hash[:limit] || hash['limit']
      offset = hash[:offset] || hash['offset']

      # Build WHERE clause from filters or direct key-value pairs
      where_parts = []

      if filters.any?
        filters.each do |filter|
          field = filter[:field] || filter['field']
          value = filter[:value] || filter['value']
          operator = filter[:operator] || filter['operator'] || '='

          where_parts << build_condition(field, value, operator)
        end
      else
        # Treat other hash keys as simple equality filters
        hash.each do |key, value|
          next if [:filters, :asc, :desc, :limit, :offset, 'filters', 'asc', 'desc', 'limit', 'offset'].include?(key)
          where_parts << build_condition(key.to_s, value, '=')
        end
      end

      # Build full query
      query_parts = []
      query_parts << "WHERE #{where_parts.join(' AND ')}" if where_parts.any?
      query_parts << "ORDERBY #{asc} ASC" if asc
      query_parts << "ORDERBY #{desc} DESC" if desc
      query_parts << "STARTPOSITION #{offset}" if offset
      query_parts << "MAXRESULTS #{limit}" if limit

      query_parts.join(' ')
    end

    def self.build_from_array(array)
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
            limit = "MAXRESULTS #{value}"
          when 'offset'
            offset = "STARTPOSITION #{value}"
          else
            where_parts << build_condition(field, value, operator || '=') if field
          end
        end
      end

      query_parts = []
      query_parts << "WHERE #{where_parts.join(' AND ')}" if where_parts.any?
      query_parts << order_by if order_by
      query_parts << offset if offset
      query_parts << limit if limit

      query_parts.join(' ')
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
