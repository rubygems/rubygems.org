require "test_helper"

class GemCachePurgerTest < ActiveSupport::TestCase
  context "#call" do
    setup do
      @gem_name = "test123"
    end

    should "expire API memcached" do
      Rails.cache.expects(:delete).with("info/#{@gem_name}")
      Rails.cache.expects(:delete).with("names")
      Rails.cache.expects(:delete).with("deps/v1/#{@gem_name}")

      GemCachePurger.call(@gem_name)
    end

    should "purge cdn cache" do
      Fastly.expects(:purge).with("info/#{@gem_name}", true)
      Fastly.expects(:purge).with("names", true)
      Fastly.expects(:purge).with("versions", true)

      GemCachePurger.call(@gem_name)
      Delayed::Worker.new.work_off
    end
  end
end
