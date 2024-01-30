Gemcutter::GEOIP_FIELDS = {
  continent_code: "GEOIP_CONTINENT_CODE",
  country_code: "GEOIP_COUNTRY_CODE",
  country_code3: "GEOIP_COUNTRY_CODE3",
  country_name: "GEOIP_COUNTRY_NAME",
  region: "GEOIP_REGION",
  city: "GEOIP_CITY"
}.freeze

Gemcutter::PROXY_TOKEN = ENV["RUBYGEMS_PROXY_TOKEN"].presence

ActiveSupport.on_load(:action_dispatch_request) do
  def ip_address
    fetch_header("gemcutter.ip_address") do |k|
      addr = IpAddress.find_or_create_by(ip_address: remote_ip)
      return unless addr

      token = headers["RUBYGEMS_PROXY_TOKEN"].presence
      if token && Gemcutter::PROXY_TOKEN && ActiveSupport::SecurityUtils.secure_compare(token, Gemcutter::PROXY_TOKEN)
        values = Gemcutter::GEOIP_FIELDS.transform_values { |v| headers[v] }
        values.compact!
        if values.present?
          addr.geoip_info.assign_attributes values
          addr.save if addr.will_save_change_to_attribute?(:geoip_info)
        end
      end

      set_header k, addr
    end
  end
end
