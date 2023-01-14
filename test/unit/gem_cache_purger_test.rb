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
      # Purposely uses a hash because delayed_job lacks correct support for kwargs.
      # Mocha handles kwargs correctly and complains if we expect kwargs when delay sends a hash.
      # See: https://github.com/collectiveidea/delayed_job/issues/1134
      Fastly.expects(:purge).with({ path: "info/#{@gem_name}", soft: true })
      Fastly.expects(:purge).with({ path: "gem/#{@gem_name}", soft: true })
      Fastly.expects(:purge).with({ path: "names", soft: true })
      Fastly.expects(:purge).with({ path: "versions", soft: true })

      GemCachePurger.call(@gem_name)
      Delayed::Worker.new.work_off
    end
  end
end
