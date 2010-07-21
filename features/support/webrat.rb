module Webrat
  module Logging
    def logger
      Rails.logger
    end
  end

  class Field
    def parse_rails_request_params(params)
      Rack::Utils.parse_nested_query(params)
    end
  end
end
