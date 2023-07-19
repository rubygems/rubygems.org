require "test_helper"

class OIDC::IdTokenPolicyTest < ActiveSupport::TestCase
  setup do
    @id_token = FactoryBot.create(:oidc_id_token)

    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@id_token], Pundit.policy_scope!(
      @admin,
      OIDC::IdToken
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, OIDC::IdToken), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, OIDC::IdToken), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @id_token), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @id_token), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, OIDC::IdToken), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, OIDC::IdToken), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @id_token), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @id_token), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @id_token), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @id_token), :avo_destroy?
  end
end
