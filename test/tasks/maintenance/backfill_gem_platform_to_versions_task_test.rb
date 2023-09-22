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
    include SemanticLogger::Test::Minitest

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

    should "handle full_name casing collisions" do
      rubygem1 = create(:rubygem, name: "rubygem")
      rubygem2 = create(:rubygem)
      rubygem2.update_attribute(:name, "RubyGem")

      v1 = build(:version, rubygem: rubygem1, number: "1", platform: "ruby", gem_platform: nil).tap do |v|
        v.validate
        v.save!(validate: false)
      end
      v2 = build(:version, rubygem: rubygem2, number: "1", platform: "ruby", gem_platform: nil).tap do |v|
        v.validate
        v.save!(validate: false)
      end

      logger = SemanticLogger::Test::CaptureLogEvents.new
      Maintenance::BackfillGemPlatformToVersionsTask.stubs(:logger).returns(logger)

      Maintenance::BackfillGemPlatformToVersionsTask.process(v1)
      Maintenance::BackfillGemPlatformToVersionsTask.process(v2)

      assert_equal "ruby", v1.reload.gem_platform
      assert_equal "ruby", v2.reload.gem_platform

      assert_equal "rubygem-1", v1.gem_full_name
      assert_equal "RubyGem-1", v2.gem_full_name

      assert_equal "rubygem-1", v1.full_name
      assert_equal "RubyGem-1", v2.full_name

      assert_semantic_logger_event(
        logger.events[0],
        level:            :warn,
        message_includes: "Version rubygem-1 failed validation setting gem_platform to \"ruby\""
      )
      assert_semantic_logger_event(
        logger.events[1],
        level:            :warn,
        message_includes: "Version RubyGem-1 failed validation setting gem_platform to \"ruby\""
      )
      assert_equal 2, logger.events.size
    end
  end
end
