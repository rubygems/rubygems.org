# frozen_string_literal: true

require "test_helper"

class Api::WebHookPolicyTest < ApiPolicyTestCase
  URL = "https://example.com/hook"

  setup do
    @owner = create(:user, handle: "owner")
    @rubygem = create(:rubygem, owners: [@owner])
  end

  def policy!(api_key)
    Pundit.policy!(api_key, [:api, @record])
  end

  def key_restricted_to(rubygem)
    key_with_scope(%i[access_webhooks push_rubygem], rubygem:)
  end

  context "#index?" do
    setup { @record = WebHook }

    should_require_scope :access_webhooks, :index?
    should_require_account_wide_scope :access_webhooks, :index?
  end

  %i[create? remove?].each do |action|
    context "##{action}" do
      context "for a gem hook" do
        setup { @record = WebHook.new(rubygem: @rubygem, url: URL) }

        should "allow ApiKey restricted to the hook's gem" do
          assert_authorized key_restricted_to(@rubygem), action
        end

        should "deny ApiKey restricted to another gem" do
          refute_authorized key_restricted_to(create(:rubygem, owners: [@owner])), action
        end
      end

      context "for a global hook" do
        setup { @record = WebHook.new(url: URL) }

        should_require_scope :access_webhooks, action
        should_require_account_wide_scope :access_webhooks, action
      end
    end
  end

  context "#fire?" do
    setup { @record = WebHook.new(url: URL) }

    should_require_scope :access_webhooks, :fire?

    should "allow ApiKey restricted to a gem" do
      assert_authorized key_restricted_to(@rubygem), :fire?
    end
  end
end
