require "test_helper"

class GeoipInfoTest < ActiveSupport::TestCase
  should have_many(:ip_addresses).dependent(:nullify)
  should have_many(:user_events).class_name("Events::UserEvent").dependent(:nullify)
  should have_many(:rubygem_events).class_name("Events::RubygemEvent").dependent(:nullify)

  test "#to_s" do
    assert_equal "Buffalo, NY, US", build(:geoip_info).to_s
    assert_equal "United States of America",
      build(:geoip_info, city: nil, region: nil, country_code: nil, country_name: "United States of America").to_s
    assert_equal "Unknown", build(:geoip_info, city: nil, region: nil, country_code: nil, country_name: nil).to_s
  end
end
