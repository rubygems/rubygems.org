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
    # True only when the request carries the shared secret our Fastly service
    # attaches to every origin fetch. It is also false when no token is
    # configured in this environment and for traffic that legitimately skips
    # the edge (Kubernetes probes of /internal/*), so read `edge_bypassed?`
    # as "unverified" rather than proof of a bypass, and exclude those paths
    # in detection rules.
    def edge_verified?
      fetch_header("gemcutter.edge_verified") do |k|
        token = headers["RUBYGEMS-PROXY-TOKEN"]
        set_header k, token.present? && PROXY_TOKEN.present? && ActiveSupport::SecurityUtils.secure_compare(token, PROXY_TOKEN)
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
