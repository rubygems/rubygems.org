# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillGemPlatformToVersionsTaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return versions without a gem_platform" do
      create(:version)
      b = create(:version)
      b.update_attribute(:gem_platform, nil)

      assert_equal [b], Maintenance::BackfillGemPlatformToVersionsTask.collection.to_a
    end
  end

  context "#process" do
    should "update the gem_platform for ruby platform" do
      v = create(:version, rubygem: build(:rubygem, name: "rubygem"), number: "1", platform: "ruby")
      v.update_attribute(:gem_platform, nil)

      Maintenance::BackfillGemPlatformToVersionsTask.process(v)

      assert_equal "ruby", v.reload.gem_platform
      assert_equal "rubygem-1", v.gem_full_name
      assert_equal "rubygem-1", v.full_name
    end

    should "update the gem_platform for non-ruby platform" do
      v = create(:version, rubygem: build(:rubygem, name: "rubygem"), number: "1", platform: "jruby")
      v.update_attribute(:gem_platform, nil)

      Maintenance::BackfillGemPlatformToVersionsTask.process(v)

      assert_equal "java", v.reload.gem_platform
      assert_equal "rubygem-1-java", v.gem_full_name
      assert_equal "rubygem-1-jruby", v.full_name
    end

    should "not error on gem_platform collision" do
      rubygem = create(:rubygem, name: "rubygem")
      v1 = build(:version, rubygem: rubygem, number: "1", platform: "x64-darwin19", gem_platform: nil).tap { |v| v.save(validate: false) }
      v2 = build(:version, rubygem: rubygem, number: "1", platform: "x64-darwin-19", gem_platform: nil).tap { |v| v.save(validate: false) }

      Maintenance::BackfillGemPlatformToVersionsTask.process(v1)
      Maintenance::BackfillGemPlatformToVersionsTask.process(v2)

      assert_equal "x64-darwin-19", v1.reload.gem_platform
      assert_equal "x64-darwin-19", v2.reload.gem_platform

      assert_equal "rubygem-1-x64-darwin-19", v1.gem_full_name
      assert_equal "rubygem-1-x64-darwin-19", v2.gem_full_name

      assert_equal "rubygem-1-x64-darwin19", v1.full_name
      assert_equal "rubygem-1-x64-darwin-19", v2.full_name
    end
  end
end
