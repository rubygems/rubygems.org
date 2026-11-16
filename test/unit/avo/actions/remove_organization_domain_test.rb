# frozen_string_literal: true

require "test_helper"

class RemoveOrganizationDomainTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
    @current_user = create(:admin_github_user, :is_admin)
    Avo::Current.stubs(:user).returns(@current_user)
    @resource = Avo::Resources::OrganizationDomain.new
    @action = Avo::Actions::RemoveOrganizationDomain.new(
      record: nil,
      resource: @resource,
      user: @current_user,
      view: :show
    )
  end

  def visible_context(domain)
    resource = Data.define(:record).new(record: domain)
    Data.define(:current_user, :view, :resource).new(current_user: @current_user, view: :show, resource:)
  end

  def run_action(domain, comment: "Disputed domain, removing it 1234")
    @resource.hydrate(record: domain)
    @action.handle(
      current_user: @current_user,
      resource: @resource,
      records: [domain],
      fields: { comment: }.with_indifferent_access,
      query: nil
    )
  end

  should "soft delete a verified domain keeping row, token and checks" do
    domain = create(:organization_domain, :verified, organization: @organization)
    create(:organization_domain_check, organization_domain: domain)
    token = domain.token

    run_action(domain)

    domain = OrganizationDomain.find(domain.id)

    assert_predicate domain.deleted_at, :present?
    assert_nil domain.verified_at
    assert_equal token, domain.token
    assert_equal 1, domain.checks.count
    assert_empty @organization.domains.reload
  end

  should "soft delete a pending domain" do
    domain = create(:organization_domain, organization: @organization)

    run_action(domain)

    assert_predicate domain.reload.deleted_at, :present?
    assert_equal 1, OrganizationDomain.where(id: domain.id).count
  end

  should "record an audit" do
    domain = create(:organization_domain, :verified, organization: @organization)

    run_action(domain, comment: "Disputed by another organization")

    audit = Audit.where(auditable: domain).sole

    assert_equal "Remove Organization Domain", audit.action
    assert_equal @current_user, audit.admin_github_user
    assert_equal "Disputed by another organization", audit.comment

    changes = audit.audited_changes["records"][domain.to_global_id.to_s]["changes"]

    assert_equal %w[deleted_at updated_at verified_at], changes.keys.sort
    assert_nil changes["deleted_at"].first
    assert_nil changes["verified_at"].last
  end

  should "free the domain for another organization with a new token" do
    domain = create(:organization_domain, :verified, domain: "acme.example.com", organization: @organization)
    old_token = domain.token

    run_action(domain)

    other = create(:organization_domain, domain: "acme.example.com")
    other.update!(verified_at: Time.zone.now)

    assert_predicate other, :verified?
    refute_equal old_token, other.token
  end

  should "not modify anything without a sufficient comment" do
    domain = create(:organization_domain, :verified, organization: @organization)

    run_action(domain, comment: "short")

    assert_nil domain.reload.deleted_at
    assert_predicate domain, :verified?
    assert_equal 0, Audit.where(auditable: domain).count
  end

  should "be visible on show for rubygems-org admins" do
    action_mock = Data.define(:current_user, :view, :resource).new(current_user: @current_user, view: :show, resource: nil)

    assert action_mock.instance_exec(&Avo::Actions::RemoveOrganizationDomain.visible)
  end

  should "not be visible for an already removed domain" do
    domain = create(:organization_domain, organization: @organization)
    domain.remove!
    action_mock = visible_context(domain)

    refute action_mock.instance_exec(&Avo::Actions::RemoveOrganizationDomain.visible)
    action_mock = visible_context(create(:organization_domain))

    assert action_mock.instance_exec(&Avo::Actions::RemoveOrganizationDomain.visible)
  end

  should "not re-stamp deleted_at when run on an already removed domain" do
    domain = create(:organization_domain, organization: @organization)
    domain.remove!
    original = domain.reload.deleted_at

    travel 1.hour do
      run_action(domain)
    end

    assert_equal original, domain.reload.deleted_at
  end

  should "ask for confirmation naming the domain" do
    domain = create(:organization_domain, domain: "acme.example.com")
    action_mock = Data.define(:record).new(record: domain)

    assert_includes action_mock.instance_exec(&Avo::Actions::RemoveOrganizationDomain.message), "acme.example.com"
  end

  should "not be visible or authorized for operators outside the rubygems.org team" do
    info_data = @current_user.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    @current_user.update!(info_data:)
    action_mock = Data.define(:current_user, :view, :resource).new(current_user: @current_user, view: :show, resource: nil)

    refute action_mock.instance_exec(&Avo::Actions::RemoveOrganizationDomain.visible)
    refute_predicate @action, :authorized?
  end

  should "be authorized for rubygems.org operators" do
    assert_predicate @action, :authorized?
  end
end
