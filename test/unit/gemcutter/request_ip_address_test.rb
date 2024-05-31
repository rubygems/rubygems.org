require "test_helper"

class Gemcutter::RequestIpAddressTest < ActiveSupport::TestCase
  setup do
    @request = ActionDispatch::Request.new(
      "REMOTE_ADDR" => "127.0.0.1"
    )
  end

  should "return nil with no remote_ip" do
    @request.delete_header "REMOTE_ADDR"

    assert_nil @request.ip_address
  end

  should "return nil with invalid remote_ip" do
    @request.headers["REMOTE_ADDR"] = "invalid"

    assert_nil @request.ip_address
  end

  should "create a new ip address" do
    ip_address = @request.ip_address

    refute_nil ip_address
    assert_equal IPAddr.new("127.0.0.1"), ip_address.ip_address
    assert_equal "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0", ip_address.hashed_ip_address
    refute_predicate ip_address, :geoip_info
  end

  should "use existing ip address" do
    create(:ip_address, ip_address: "127.0.0.1")

    ip_address = @request.ip_address

    refute_nil ip_address
    assert_equal IPAddr.new("127.0.0.1"), ip_address.ip_address
    assert_equal "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0", ip_address.hashed_ip_address
  end

  should "not record GEOIP_INFO without RUBYGEMS-PROXY-TOKEN set" do
    stub_const(Gemcutter::RequestIpAddress, :PROXY_TOKEN, "abc") do
      assert_nil @request.ip_address.geoip_info
    end
  end

  should "not record GEOIP_INFO without Gemcutter::PROXY_TOKEN set" do
    @request.headers["RUBYGEMS-PROXY-TOKEN"] = "abc"

    stub_const(Gemcutter::RequestIpAddress, :PROXY_TOKEN, nil) do
      assert_nil @request.ip_address.geoip_info
    end
  end

  should "record empty GEOIP_INFO" do
    @request.headers["RUBYGEMS-PROXY-TOKEN"] = "abc"

    stub_const(Gemcutter::RequestIpAddress, :PROXY_TOKEN, "abc") do
      geoip_info = @request.ip_address.geoip_info

      refute_nil geoip_info
      assert_empty(geoip_info.attributes.except("id", "created_at", "updated_at").compact)
      assert_predicate geoip_info, :persisted?
    end
  end

  should "record GEOIP_INFO" do
    @request.headers["RUBYGEMS-PROXY-TOKEN"] = "abc"

    Gemcutter::RequestIpAddress::GEOIP_FIELDS.each_with_object(build(:geoip_info, :usa)) do |(field, header), info|
      @request.headers[header] = info[field]
    end

    stub_const(Gemcutter::RequestIpAddress, :PROXY_TOKEN, "abc") do
      geoip_info = @request.ip_address.geoip_info

      refute_nil geoip_info
      assert_equal(
        { "continent_code" => "NA", "country_code" => "US", "country_code3" => "USA",
          "country_name" => "United States of America", "region" => "NY",
          "city" => "Buffalo" },
        geoip_info.attributes.except("id", "created_at", "updated_at").compact
      )
      assert_predicate geoip_info, :persisted?
    end
  end

  should "record ignoring invalid GEOIP_INFO" do
    @request.headers["RUBYGEMS-PROXY-TOKEN"] = "abc"
    @request.headers["GEOIP-CONTINENT-CODE"] = "NAH"
    @request.headers["GEOIP-COUNTRY-CODE3"] = "NAH"

    stub_const(Gemcutter::RequestIpAddress, :PROXY_TOKEN, "abc") do
      geoip_info = @request.ip_address.geoip_info

      refute_nil geoip_info
      refute_predicate geoip_info, :persisted?
      assert_predicate @request.ip_address, :persisted?
    end
  end
end
