# frozen_string_literal: true

require "test_helper"

# test "#process performs a task iteration" do
#   Maintenance::BackfillGemS3MetadataTask.process(element)
# end
class Maintenance::BackfillGemS3MetadataTaskTest < ActiveSupport::TestCase
  include SemanticLogger::Test::Minitest

  make_my_diffs_pretty!

  test "#collection returns a collection of indexed versions" do
    create(:version, indexed: false)
    v = create(:version, indexed: true)

    assert_equal [v], Maintenance::BackfillGemS3MetadataTask.collection.to_a
  end

  test "#process makes no changes for newly pushed gems" do
    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"

    assert_no_changes -> { [pusher.version.reload.updated_at, RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")] } do
      Maintenance::BackfillGemS3MetadataTask.process(pusher.version)
    end
  end

  test "#process logs missing gem contents" do
    logger = SemanticLogger::Test::CaptureLogEvents.new
    Maintenance::BackfillGemS3MetadataTask.stubs(:logger).returns(logger)

    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"

    # remove metadata from the fs
    RubygemFs.instance.remove("gems/bin_and_img-0.1.0.gem")

    assert_no_changes -> { [pusher.version.reload.updated_at, RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")] } do
      Maintenance::BackfillGemS3MetadataTask.process(pusher.version)
    end

    assert_semantic_logger_event(
      logger.events[0],
        level:            :error,
        message_includes: "Version bin_and_img-0.1.0 has no gem contents"
    )
    assert_equal 1, logger.events.size
  end

  test "#process logs sha256 mismatch" do
    logger = SemanticLogger::Test::CaptureLogEvents.new
    Maintenance::BackfillGemS3MetadataTask.stubs(:logger).returns(logger)

    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"

    # remove metadata from the fs
    RubygemFs.instance.remove("gems/bin_and_img-0.1.0.gem")
    RubygemFs.instance.store("gems/bin_and_img-0.1.0.gem", "contents")

    assert_no_changes -> { [pusher.version.reload.updated_at, RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")] } do
      Maintenance::BackfillGemS3MetadataTask.process(pusher.version)
    end

    assert_semantic_logger_event(
      logger.events[0],
        level:            :error,
        message_includes: "Version bin_and_img-0.1.0 has sha256 mismatch"
    )
    assert_equal 1, logger.events.size
  end

  test "#process logs unexpected metadata" do
    logger = SemanticLogger::Test::CaptureLogEvents.new
    Maintenance::BackfillGemS3MetadataTask.stubs(:logger).returns(logger)

    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"

    # remove metadata from the fs
    body, response = RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")
    RubygemFs.instance.store("gems/bin_and_img-0.1.0.gem", body, metadata: response[:metadata].merge("unexpected" => "value"))

    assert_no_changes -> { [pusher.version.reload.updated_at, RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")] } do
      Maintenance::BackfillGemS3MetadataTask.process(pusher.version)
    end

    assert_semantic_logger_event(
      logger.events[0],
        level:            :error,
        message_includes: "Version bin_and_img-0.1.0 has unexpected metadata"
    )
    assert_equal 1, logger.events.size
  end

  test "#process logs conflicting metadata" do
    logger = SemanticLogger::Test::CaptureLogEvents.new
    Maintenance::BackfillGemS3MetadataTask.stubs(:logger).returns(logger)

    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"

    # remove metadata from the fs
    body, response = RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")
    RubygemFs.instance.store("gems/bin_and_img-0.1.0.gem", body, metadata: response[:metadata].merge("gem" => "not_bin_and_img"))

    assert_no_changes -> { [pusher.version.reload.updated_at, RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")] } do
      Maintenance::BackfillGemS3MetadataTask.process(pusher.version)
    end

    assert_semantic_logger_event(
      logger.events[0],
        level:            :error,
        message_includes: "Version bin_and_img-0.1.0 has unexpected metadata"
    )
    assert_equal 1, logger.events.size
  end

  test "#process updates metadata" do
    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"

    # remove metadata from the fs
    body, = RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")
    RubygemFs.instance.store("gems/bin_and_img-0.1.0.gem", body, metadata: {})

    assert_no_changes -> { [pusher.version.reload.updated_at] } do
      Maintenance::BackfillGemS3MetadataTask.process(pusher.version)
    end

    assert_equal [
      @gem.tap(&:rewind).read,
      checksum_sha256: pusher.version.sha256,
      metadata: { "gem" => "bin_and_img",
                  "version" => "0.1.0",
                  "platform" => "ruby",
                  "surrogate-key" => "gem/bin_and_img",
                  "sha256" => pusher.version.sha256 },
      key: "gems/bin_and_img-0.1.0.gem"
    ], RubygemFs.instance.get_object("gems/bin_and_img-0.1.0.gem")
  end
end
