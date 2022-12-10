require "test_helper"

class GravatarTest < ActiveSupport::TestCase
  context "initialization" do
    setup do
      @user = build(:user, email: "mail@example.com")
    end

    should "initialize without a designated size" do
      gravatar = Gravatar.new(@user)
      assert_instance_of Gravatar, gravatar
    end

    should "initialize with a designated size" do
      gravatar = Gravatar.new(@user, size: 120)
      assert_instance_of Gravatar, gravatar
    end
  end

  # Default Gravatar for hidden emails: https://www.gravatar.com/avatar/00000000000000000000000000000000.png
  context "with a User with a private email" do
    setup do
      @user = build(:user, email: "mail@example.com", hide_email: true)
      @gravatar = Gravatar.new(@user)
    end

    should "reference a default profile image from Gravatar" do
      assert_match Gravatar::GRAVATAR_DEFAULT_ID, @gravatar.url
    end

    should "not reference the user's email address" do
      @user.stubs(:email).raises("User#email was called when it should not have been.")
      @gravatar.url
    end
  end
end
