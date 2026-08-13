# frozen_string_literal: true

require "test_helper"

class ChangeApiKeyNameTest < ActiveSupport::TestCase
  setup do
    @api_key = create(:api_key, name: "person@example.com")
    @current_user = create(:admin_github_user, :is_admin)
    Avo::Current.stubs(:user).returns(@current_user)
    @resource = Avo::Resources::ApiKey.new.hydrate(record: @api_key)
    @action = Avo::Actions::ChangeApiKeyName.new(record: @api_key, resource: @resource, user: @current_user, view: :show)
  end

  should "ask for confirmation naming the API key" do
    message = @action.get_message

    assert_includes message, @api_key.name
    assert_includes message, "##{@api_key.id}"
  end

  should "be registered on the API key resource" do
    action_classes = Avo::Resources::ApiKey.new.get_actions.pluck(:class)

    assert_includes action_classes, Avo::Actions::ChangeApiKeyName
  end

  should "prefill the current name and require the standard audited comment" do
    @action.fields
    fields = @action.get_field_definitions.index_by(&:id)
    name_field = fields.fetch(:new_name).hydrate(record: @api_key, resource: @resource)

    assert name_field.required
    assert_equal @api_key.name, name_field.computed_default_value
    assert fields.fetch(:comment).required
  end

  should "change the API key name and record an Avo audit" do
    comment = "Removing personal information at the owner's request"

    @action.handle(**action_args(new_name: "redacted-key", comment:))

    assert_equal "redacted-key", @api_key.reload.name

    audit = Audit.sole

    assert_equal comment, audit.comment
    assert_equal "Change API Key Name", audit.action
    assert_equal ["person@example.com", "redacted-key"],
      audit.audited_changes.dig("records", @api_key.to_global_id.uri.to_s, "changes", "name")
    assert_equal({ "new_name" => "redacted-key" }, audit.audited_changes.fetch("fields"))
    assert_equal "API key ##{@api_key.id} has been renamed to \"redacted-key\"", @action.response.dig(:messages, 0, :body)
  end

  should "change the name of an expired API key" do
    @api_key.update_column(:expires_at, 1.hour.ago)

    @action.handle(**action_args(new_name: "redacted-key", comment: "Removing PII from an expired API key"))

    assert_equal "redacted-key", @api_key.reload.name
    assert_equal "Change API Key Name", Audit.sole.action
  end

  should "reject an invalid API key name" do
    @action.handle(**action_args(new_name: "", comment: "Attempting to remove PII from this API key"))

    assert_equal "person@example.com", @api_key.reload.name
    assert_equal :error, @action.response.dig(:messages, 0, :type)
    assert_equal "Name can't be blank", @action.response.dig(:messages, 0, :body)
  end

  should "be visible and authorized for rubygems.org operators on the API key page" do
    action_context = Data.define(:current_user, :resource, :view).new(
      current_user: @current_user,
      resource: @resource,
      view: Avo::ViewInquirer.new(:show)
    )

    assert action_context.instance_exec(&Avo::Actions::ChangeApiKeyName.visible)
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

    refute action_context.instance_exec(&Avo::Actions::ChangeApiKeyName.visible)
    refute_predicate @action, :authorized?
  end

  private

  def action_args(new_name:, comment:)
    {
      current_user: @current_user,
      resource: @resource,
      records: [@api_key],
      fields: { new_name:, comment: },
      query: nil
    }
  end
end
