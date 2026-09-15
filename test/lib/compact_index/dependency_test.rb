# frozen_string_literal: true

require "test_helper"
require "compact_index"

class CompactIndex::DependencyTest < ActiveSupport::TestCase
  context "#version_and_platform" do
    should "include platform for non-ruby platform" do
      dep = CompactIndex::Dependency.new("foo", "=1.0", "jruby", "abc")

      assert_equal "=1.0-jruby", dep.version_and_platform
    end

    should "exclude platform for ruby platform" do
      dep = CompactIndex::Dependency.new("foo", "=1.0", "ruby", "abc")

      assert_equal "=1.0", dep.version_and_platform
    end
  end
end
