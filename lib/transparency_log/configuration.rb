# frozen_string_literal: true

module TransparencyLog
    class Configuration
        attr_accessor :rekor_url
    end

    def initialize
        @rekor_url = "http://localhost:3004"
    end
end
