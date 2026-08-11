# frozen_string_literal: true

require "test_helper"

class ApiKeyOrganizationScopeTest < ActiveSupport::TestCase
  setup do
    @api_key_organization_scope = create(:api_key_organization_scope)
  end

  subject { @api_key_organization_scope }

  should belong_to :api_key
  should belong_to :membership
  should validate_uniqueness_of(:membership_id).scoped_to(:api_key_id)

  should "be valid with factory" do
    assert_predicate build(:api_key_organization_scope), :valid?
  end

  should "delegate organization to membership" do
    organization = create(:organization)
    membership = create(:membership, :admin, organization: organization)
    scope = build(:api_key_organization_scope, membership: membership)

    assert_equal organization, scope.organization
  end
end
