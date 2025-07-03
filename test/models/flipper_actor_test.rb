# test/lib/flipper_actor_test.rb
require 'test_helper'

class FlipperActorTest < ActiveSupport::TestCase
  def setup
    @user = create(:user, handle: "user_handle")
    @organization = create(:organization, handle: "organization_handle")
  end

  test "initializes with a record" do
    actor = FlipperActor.new(@user)

    assert_equal @user, actor.record
    assert_equal "User;user_handle", actor.flipper_id
  end

  test "to_s returns formatted string" do
    user_actor = FlipperActor.new(@user)
    org_actor = FlipperActor.new(@organization)

    assert_equal "user_handle (User)", user_actor.to_s
    assert_equal "organization_handle (Organization)", org_actor.to_s
  end

  test "find returns FlipperActor for existing user" do
    actor = FlipperActor.find("User;user_handle")

    assert_not_nil actor
    assert_instance_of FlipperActor, actor
    assert_equal @user, actor.record
  end

  test "find returns FlipperActor for existing organization" do
    actor = FlipperActor.find("Organization;organization_handle")

    assert_not_nil actor
    assert_instance_of FlipperActor, actor
    assert_equal @organization, actor.record
  end

  test "find returns nil for non-existent user" do
    actor = FlipperActor.find("User;non_existent")

    assert_nil actor
  end

  test "find returns nil for non-existent organization" do
    actor = FlipperActor.find("Organization;non_existent")

    assert_nil actor
  end

  test "find returns nil for unknown actor type" do
    actor = FlipperActor.find("Unknown;some_name")

    assert_nil actor
  end

  test "find handles malformed flipper_id gracefully" do
    actor = FlipperActor.find("malformed_id")

    assert_nil actor
  end

  test "flipper_id matches expected format" do
    user_actor = FlipperActor.new(@user)
    org_actor = FlipperActor.new(@organization)

    assert_equal "User;user_handle", user_actor.flipper_id
    assert_equal "Organization;organization_handle", org_actor.flipper_id
  end
end
