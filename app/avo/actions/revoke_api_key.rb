# frozen_string_literal: true

class Avo::Actions::RevokeApiKey < Avo::Actions::ApplicationAction
  self.name = "Revoke API Key"
  self.visible = lambda {
    Admin::ApiKeyPolicy.new(current_user, resource.record).act_on? && view == :show
  }
  self.authorize = lambda {
    Admin::ApiKeyPolicy.new(current_user, action.record).act_on?
  }
  self.message = lambda {
    "Are you sure you would like to revoke API key #{record.name.inspect} (##{record.id})?"
  }
  self.confirm_button_label = "Revoke API Key"

  def self.already_revoked_reason
    "Already revoked because this API key has expired."
  end

  def enabled?
    super && !record.expired?
  end

  def action_name
    return super unless record&.expired?

    "#{super} — #{self.class.already_revoked_reason}"
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(api_key)
      already_revoked = api_key.with_lock do
        if api_key.expired?
          true
        else
          api_key.expire!
          false
        end
      end

      return error(Avo::Actions::RevokeApiKey.already_revoked_reason) if already_revoked

      succeed("API key #{api_key.name.inspect} (##{api_key.id}) has been revoked")
    end
  end
end
