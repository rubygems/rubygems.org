# frozen_string_literal: true

require "test_helper"

class RecorderTest < ActiveSupport::TestCase
  setup do
    @controller = Class.new do
      include Recorder
    end.new
  end

  test "records a gem push event when record is a Pusher" do
    user = create(:user)
    api_key = create(:api_key, owner: user)
    rubygem = create(:rubygem, name: "test")
    version = create(:version, rubygem: rubygem)

    pusher = Pusher.allocate
    pusher.stubs(:rubygem).returns(rubygem)
    pusher.stubs(:version).returns(version)

    @controller.instance_variable_set(:@api_key, api_key)

    recorder = mock
    TransparencyLog::Recorder.expects(:new).returns(recorder)

    recorder.expects(:record).with({
      event_type: "gem_push",
      resource_type: "rubygem",
      resource_name: rubygem.name,
      resource_id: rubygem.id.to_s,
      subject_type: "gem_version",
      subject_name: version.full_name,
      subject_id: version.id.to_s,
      actor_type: api_key.user? ? "user" : "unknown",
      actor_id: api_key.owner_id.to_s,
      actor_handle: api_key.owner&.name,
      authentication_method: "api_key"
    })

    @controller.send(:record_transparency_log_event, "gem_push", pusher)
  end

  test "records an ownership change event when record is a User" do
    actor = create(:user)
    owner = create(:user)
    api_key = create(:api_key, owner: actor)
    rubygem = create(:rubygem)

    @controller.instance_variable_set(:@api_key, api_key)
    @controller.instance_variable_set(:@rubygem, rubygem)

    recorder = mock
    TransparencyLog::Recorder.expects(:new).returns(recorder)

    recorder.expects(:record).with({
      event_type: "owner_add",
      resource_type: "rubygem",
      resource_name: rubygem.name,
      resource_id: rubygem.id.to_s,
      subject_type: "user",
      subject_name: owner.handle,
      subject_id: owner.id.to_s,
      actor_type: "user",
      actor_id: api_key.user.id.to_s,
      actor_handle: api_key.user.handle,
      authentication_method: "api_key"
    })

    @controller.send(:record_transparency_log_event, "owner_add", owner)
  end

  test "does not record an event for an unsupported record type" do
    TransparencyLog::Recorder.expects(:new).never

    @controller.send(:record_transparency_log_event, "unknown_event", Object.new)
  end

  test "reports errors without raising them" do
    api_key = create(:api_key)
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)
    error = StandardError.new("recording failed")

    pusher = Pusher.allocate
    pusher.stubs(:rubygem).returns(rubygem)
    pusher.stubs(:version).returns(version)

    @controller.instance_variable_set(:@api_key, api_key)

    TransparencyLog::Recorder
      .expects(:new)
      .raises(error)

    Rails.error.expects(:report).with(error, handled: true)

    assert_nothing_raised do
      @controller.send(:record_transparency_log_event, "gem_push", pusher)
    end
  end
end
