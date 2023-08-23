# frozen_string_literal: true

require "test_helper"

class Maintenance::VerifyGemContentsInFsTaskTest < ActiveSupport::TestCase
  def task(**attrs)
    task = Maintenance::VerifyGemContentsInFsTask.new
    task.assign_attributes(attrs)
    task.stubs(logger: SemanticLogger::Test::CaptureLogEvents.new)
    task
  end

  teardown do
    RubygemFs.mock!
  end

  context "#process" do
    include SemanticLogger::Test::Minitest

    should "not error without anything uploaded" do
      version = create(:version)
      @task = task
      @task.process(version)

      assert_equal 2, @task.logger.events.size
      assert_semantic_logger_event(
        @task.logger.events[0],
        level:            :warn,
        message_includes: "is missing gem contents"
      )
      assert_semantic_logger_event(
        @task.logger.events[1],
        level:            :warn,
        message_includes: ".gemspec.rz is missing"
      )
    end

    should "not error when checksums match" do
      gem = "foo-1.0.0.gem"
      sha256 = Digest::SHA256.base64digest(gem)
      version = create(:version, sha256:)
      RubygemFs.instance.store("gems/#{version.full_name}.gem", gem)
      RubygemFs.instance.store("quick/Marshal.4.8/#{version.full_name}.gemspec.rz", "")

      @task = task
      @task.process(version)

      assert_empty @task.logger.events
    end

    should "error when checksums do not match" do
      version = create(:version, sha256: "abcd")
      RubygemFs.instance.store("gems/#{version.full_name}.gem", "abcd")
      RubygemFs.instance.store("quick/Marshal.4.8/#{version.full_name}.gemspec.rz", "")

      @task = task
      @task.process(version)

      assert_equal 1, @task.logger.events.size
      assert_semantic_logger_event(
        @task.logger.events[0],
        level:            :error,
        message_includes: "has incorrect checksum (expected abcd, got #{Digest::SHA256.base64digest('abcd')})"
      )
    end
  end

  context "#collection" do
    should "return all versions when no filters are provided" do
      create_list(:version, 10)

      assert_equal 10, task.collection.count
    end

    should "filter by full name" do
      create_list(:version, 10)

      assert_empty task(full_name_pattern: "^.$").collection
    end

    should "filter by rubygem name" do
      create(:version, rubygem: create(:rubygem, name: "a"))
      create(:version, rubygem: create(:rubygem, name: "abcd"))

      assert_equal 1, task(gem_name_pattern: "^.$").collection.count
    end
  end

  context "#valid?" do
    should "return true when no patterns given" do
      assert_predicate task, :valid?
    end

    should "return true when patterns are valid" do
      assert_predicate task(gem_name_pattern: "^.+$", full_name_pattern: "-\\d"), :valid?
    end

    should "return false when patterns are not valid" do
      refute_predicate task(gem_name_pattern: "(", full_name_pattern: "["), :valid?
    end
  end
end
