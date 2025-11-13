module Helpers
  def self.format_error(error)
    if error.is_a?(StandardError)
      "Error: #{error.message}"
    elsif error.is_a?(String)
      "Error: #{error}"
    else
      "Unknown error: #{error.inspect}"
    end
  end
end
