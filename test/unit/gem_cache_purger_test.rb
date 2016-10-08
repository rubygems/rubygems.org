require 'test_helper'

class GemCachePurgerTest < ActiveSupport::TestCase
  context "#call" do
    setup do
      Rails.cache.stubs(:delete)
      Fastly.stubs(:purge)

      @gem_name = 'test123'
      GemCachePurger.call(@gem_name)
    end

    should "expire API memcached" do
      assert_received(Rails.cache, :delete) { |cache| cache.with("info/#{@gem_name}") }
      assert_received(Rails.cache, :delete) { |cache| cache.with("names") }
      assert_received(Rails.cache, :delete) { |cache| cache.with("deps/v1/#{@gem_name}") }
    end

    should "purge cdn cache" do
      Delayed::Worker.new.work_off
      assert_received(Fastly, :purge) { |path| path.with("info/#{@gem_name}") }
      assert_received(Fastly, :purge) { |path| path.with("names") }
      assert_received(Fastly, :purge) { |path| path.with("versions") }
    end
  end
end
