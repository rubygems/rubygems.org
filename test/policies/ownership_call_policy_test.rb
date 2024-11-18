require "test_helper"

class OwnershipCallPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @ownership_call = @rubygem.ownership_calls.create(user: @owner, note: "valid note")

    @user = create(:user)
  end

  def policy!(user)
    Pundit.policy!(user, @ownership_call)
  end

  def test_create
    assert_authorized @owner, :create?
    refute_authorized @user, :create?
  end

  def test_close
    assert_authorized @owner, :close?
    refute_authorized @user, :close?
  end
end
