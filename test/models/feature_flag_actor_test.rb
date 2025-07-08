require "test_helper"

class FeatureFlagActorTest < ActiveSupport::TestCase
  def setup
    @user = create(:user, handle: "user_handle")
    @organization = create(:organization, handle: "org_handle")
  end

  test "initializes with a record" do
    actor = FeatureFlagActor.new(@user)

    assert_equal @user, actor.record
    assert_equal "user:user_handle", actor.flipper_id
  end

  test "to_s returns formatted string" do
    user_actor = FeatureFlagActor.new(@user)
    org_actor = FeatureFlagActor.new(@organization)

    assert_equal "user_handle (User)", user_actor.to_s
    assert_equal "org_handle (Organization)", org_actor.to_s
  end

  test "find returns FeatureFlagActor for existing user" do
    actor = FeatureFlagActor.find("user:user_handle")

    assert_not_nil actor
    assert_instance_of FeatureFlagActor, actor
    assert_equal @user, actor.record
  end

  test "find returns FeatureFlagActor for existing organization" do
    actor = FeatureFlagActor.find("org:org_handle")

    assert_not_nil actor
    assert_instance_of FeatureFlagActor, actor
    assert_equal @organization, actor.record
  end

  test "find returns nil for non-existent user" do
    actor = FeatureFlagActor.find("user:non_existent")

    assert_nil actor
  end

  test "find returns nil for non-existent organization" do
    actor = FeatureFlagActor.find("org:non_existent")

    assert_nil actor
  end

  test "find returns nil for unknown actor type" do
    actor = FeatureFlagActor.find("team:some_name")

    assert_nil actor
  end

  test "find handles malformed flipper_id gracefully" do
    actor = FeatureFlagActor.find("malformed_id")

    assert_nil actor
  end

  test "flipper_id matches expected format" do
    user_actor = FeatureFlagActor.new(@user)
    org_actor = FeatureFlagActor.new(@organization)

    assert_equal "user:user_handle", user_actor.flipper_id
    assert_equal "org:org_handle", org_actor.flipper_id
  end
end
