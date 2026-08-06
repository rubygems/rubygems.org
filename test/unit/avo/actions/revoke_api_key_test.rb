# frozen_string_literal: true

require "test_helper"

class RevokeApiKeyTest < ActiveSupport::TestCase
  setup do
    @api_key = create(:api_key, name: "compromised-deploy-key")
    @current_user = create(:admin_github_user, :is_admin)
    @resource = Avo::Resources::ApiKey.new.hydrate(record: @api_key)
    @action = Avo::Actions::RevokeApiKey.new(record: @api_key, resource: @resource, user: @current_user, view: :show)
  end

  should "ask for confirmation naming the API key" do
    message = @action.get_message

    assert_includes message, @api_key.name
    assert_includes message, "##{@api_key.id}"
  end

  should "be registered on the API key resource" do
    action_classes = Avo::Resources::ApiKey.new.get_actions.pluck(:class)

    assert_includes action_classes, Avo::Actions::RevokeApiKey
  end

  should "require the standard audited comment" do
    @action.fields
    comment_field = @action.get_field_definitions.find { |field| field.id == :comment }

    assert comment_field.required
  end

  should "expire the API key with its existing event semantics and an Avo audit" do
    comment = "Revoking a compromised deployment credential"
    user = @api_key.user

    assert_difference -> { user.events.where(tag: Events::UserEvent::API_KEY_DELETED).count }, 1 do
      @action.handle(**action_args(comment:))
    end

    assert_predicate @api_key.reload, :expired?
    event = user.events.where(tag: Events::UserEvent::API_KEY_DELETED).sole

    assert_equal @api_key.name, event.additional.name

    audit = Audit.sole

    assert_equal comment, audit.comment
    assert_equal "Revoke API Key", audit.action
    assert_equal "API key #{@api_key.name.inspect} (##{@api_key.id}) has been revoked", @action.response.dig(:messages, 0, :body)
  end

  should "be visible and authorized for rubygems.org operators on the API key page" do
    action_context = Data.define(:current_user, :resource, :view).new(
      current_user: @current_user,
      resource: @resource,
      view: Avo::ViewInquirer.new(:show)
    )

    assert action_context.instance_exec(&Avo::Actions::RevokeApiKey.visible)
    assert_predicate @action, :authorized?
  end

  should "not be visible or authorized for operators outside the rubygems.org team" do
    info_data = @current_user.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    @current_user.update!(info_data:)
    action_context = Data.define(:current_user, :resource, :view).new(
      current_user: @current_user,
      resource: @resource,
      view: Avo::ViewInquirer.new(:show)
    )

    refute action_context.instance_exec(&Avo::Actions::RevokeApiKey.visible)
    refute_predicate @action, :authorized?
  end

  should "not be visible or authorized for non-admin rubygems.org team members" do
    @current_user.update!(is_admin: false)
    action_context = Data.define(:current_user, :resource, :view).new(
      current_user: @current_user,
      resource: @resource,
      view: Avo::ViewInquirer.new(:show)
    )

    assert @current_user.team_member?("rubygems-org")
    refute action_context.instance_exec(&Avo::Actions::RevokeApiKey.visible)
    refute_predicate @action, :authorized?
  end

  should "not be visible outside the API key show page" do
    action_context = Data.define(:current_user, :resource, :view).new(
      current_user: @current_user,
      resource: @resource,
      view: Avo::ViewInquirer.new(:index)
    )

    refute action_context.instance_exec(&Avo::Actions::RevokeApiKey.visible)
  end

  should "be disabled and safely reject an already-expired API key" do
    @api_key.update_column(:expires_at, 1.hour.ago)
    original_expires_at = @api_key.reload.expires_at

    refute_predicate @action, :enabled?
    assert_includes @action.action_name, Avo::Actions::RevokeApiKey.already_revoked_reason

    assert_no_difference -> { @api_key.user.events.where(tag: Events::UserEvent::API_KEY_DELETED).count } do
      @action.handle(**action_args(comment: "Confirming this key was already revoked"))
    end

    assert_equal original_expires_at, @api_key.reload.expires_at
    assert_equal :error, @action.response.dig(:messages, 0, :type)
    assert_equal Avo::Actions::RevokeApiKey.already_revoked_reason, @action.response.dig(:messages, 0, :body)
  end

  should "safely reject revocation through a stale API key instance" do
    stale_api_key = ApiKey.find(@api_key.id)
    @api_key.expire!
    original_expires_at = @api_key.reload.expires_at

    assert_no_difference -> { @api_key.user.events.where(tag: Events::UserEvent::API_KEY_DELETED).count } do
      @action.handle(**action_args(comment: "Confirming this stale key was already revoked", records: [stale_api_key]))
    end

    assert_equal original_expires_at, @api_key.reload.expires_at
    assert_equal :error, @action.response.dig(:messages, 0, :type)
    assert_equal Avo::Actions::RevokeApiKey.already_revoked_reason, @action.response.dig(:messages, 0, :body)
  end

  private

  def action_args(comment:, records: [@api_key])
    {
      current_user: @current_user,
      resource: @resource,
      records:,
      fields: { comment: },
      query: nil
    }
  end
end
