# frozen_string_literal: true

require "test_helper"

class Admin::AdvisoryPolicyTest < AdminPolicyTestCase
  setup do
    @advisory = create(:advisory)
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_associations
    assert_association @admin, @advisory, :rubygem, Admin::RubygemPolicy
  end

  def test_scope
    assert_equal [@advisory], policy_scope!(
      @admin,
      Advisory
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, Advisory, :avo_index?

    refute_authorizes @non_admin, Advisory, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @advisory, :avo_show?

    refute_authorizes @non_admin, @advisory, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, Advisory, :avo_create?
    refute_authorizes @non_admin, Advisory, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @advisory, :avo_update?
    refute_authorizes @non_admin, @advisory, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @advisory, :avo_destroy?
    refute_authorizes @non_admin, @advisory, :avo_destroy?
  end

  def test_act_on
    assert_authorizes @admin, @advisory, :act_on?
    refute_authorizes @non_admin, @advisory, :act_on?
  end
end
