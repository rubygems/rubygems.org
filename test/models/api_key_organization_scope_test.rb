# frozen_string_literal: true

require "test_helper"

class ApiKeyOrganizationScopeTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @membership = @user.memberships.find_by!(organization: @organization)
    @api_key = create(:api_key, owner: @user, scopes: %w[push_rubygem], scoped_organization: @organization)
    @api_key_scope = @api_key.api_key_organization_scope
  end

  subject { @api_key_scope }

  should belong_to :api_key
  should belong_to :membership
  should validate_uniqueness_of(:membership_id).scoped_to(:api_key_id)

  should "be valid with factory" do
    assert_predicate build(:api_key_organization_scope), :valid?
  end

  should "delegate organization to membership" do
    assert_equal @organization, @api_key_scope.organization
  end

  context "#soft_delete_api_key!" do
    should "be called if destroyed by association" do
      @membership.destroy!

      assert_nil @api_key.reload.api_key_organization_scope
      assert_predicate @api_key, :soft_deleted?
      assert_predicate @api_key, :soft_deleted_by_organization?
      assert_equal @organization.name, @api_key.reload.soft_deleted_organization_name
    end

    should "not soft delete if not destroyed by association" do
      @api_key.update(membership: nil)

      assert_nil @api_key.reload.api_key_organization_scope
      refute_predicate @api_key, :soft_deleted?
      refute_predicate @api_key, :soft_deleted_by_organization?
      assert_nil @api_key.reload.soft_deleted_organization_name
    end
  end

  context "when role is downgraded below admin" do
    should "soft delete org scoped api keys" do
      @membership.update!(role: :maintainer)

      assert_nil @api_key.reload.api_key_organization_scope
      assert_predicate @api_key, :soft_deleted?
      assert_predicate @api_key, :soft_deleted_by_organization?
      assert_equal @organization.name, @api_key.soft_deleted_organization_name
    end

    should "not soft delete org scoped api keys when role remains admin" do
      @membership.update!(role: :admin)

      assert_predicate @api_key.reload.api_key_organization_scope, :present?
      refute_predicate @api_key, :soft_deleted?
    end
  end
end
