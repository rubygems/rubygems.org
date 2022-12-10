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
end
