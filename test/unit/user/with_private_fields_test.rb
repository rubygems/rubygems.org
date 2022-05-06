require "test_helper"

class User::WithPrivateFieldsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  context "#warnings" do
  end

  context "#mfa_warnings" do
  end
end
