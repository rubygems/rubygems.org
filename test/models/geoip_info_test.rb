require "test_helper"

class GeoipInfoTest < ActiveSupport::TestCase
  test "#to_s" do
    assert_equal "Buffalo, NY, US", build(:geoip_info).to_s
    assert_equal "United States of America", build(:geoip_info, city: nil, region: nil, country_code: nil).to_s
    assert_equal "Unknown", build(:geoip_info, city: nil, region: nil, country_code: nil, country_name: nil).to_s
  end
end
