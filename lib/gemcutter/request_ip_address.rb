# frozen_string_literal: true

module Gemcutter::RequestIpAddress
  extend ActiveSupport::Concern

  GEOIP_FIELDS = {
    continent_code: "GEOIP-CONTINENT-CODE",
    country_code: "GEOIP-COUNTRY-CODE",
    country_code3: "GEOIP-COUNTRY-CODE3",
    country_name: "GEOIP-COUNTRY-NAME",
    region: "GEOIP-REGION",
    city: "GEOIP-CITY"
  }.freeze

  PROXY_TOKEN = ENV["RUBYGEMS_PROXY_TOKEN"].presence.freeze

  included do
    def ip_address
      fetch_header("gemcutter.ip_address") do |k|
        return if remote_ip.blank?
        ip_addr = begin
          IPAddr.new(remote_ip)
        rescue IPAddr::InvalidAddressError
          nil
        end
        return unless ip_addr

        addr = IpAddress.find_or_create_by(ip_address: ip_addr)
        return unless addr

        token = headers["RUBYGEMS-PROXY-TOKEN"].presence

        if token && PROXY_TOKEN && ActiveSupport::SecurityUtils.secure_compare(token, PROXY_TOKEN)
          values = GEOIP_FIELDS.transform_values { |v| headers[v] }
          geoip_info = GeoipInfo.find_or_create_by(**values)
          addr.update(geoip_info:)
        end

        set_header k, addr
      end
    end
  end
end
