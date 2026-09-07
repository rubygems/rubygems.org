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
    # True only when the request carries the shared proxy token that our Fastly
    # service sets on every origin request. A request that reached the origin
    # any other way (directly to the load balancer, or via another Fastly
    # account) fails this check. The guard mirrors the one used for GeoIP on
    # purpose: secure_compare raises on nil, and PROXY_TOKEN is nil when the
    # environment variable is unset.
    def edge_verified?
      fetch_header("gemcutter.edge_verified") do |k|
        token = headers["RUBYGEMS-PROXY-TOKEN"].presence
        verified = !!(token && PROXY_TOKEN && ActiveSupport::SecurityUtils.secure_compare(token, PROXY_TOKEN))
        set_header k, verified
      end
    end

    def edge_bypassed?
      !edge_verified?
    end

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

        if edge_verified?
          values = GEOIP_FIELDS.transform_values { |v| headers[v] }
          geoip_info = GeoipInfo.find_or_create_by(**values)
          addr.update(geoip_info:)
        end

        set_header k, addr
      end
    end
  end
end
