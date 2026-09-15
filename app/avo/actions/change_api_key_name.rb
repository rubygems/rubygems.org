# frozen_string_literal: true

class Avo::Actions::ChangeApiKeyName < Avo::Actions::ApplicationAction
  def fields
    field :new_name, name: "Name", as: :text, required: true, default: -> { record.name }
    super
  end

  self.name = "Change API Key Name"
  self.visible = lambda {
    Admin::ApiKeyPolicy.new(current_user, resource.record).act_on? && view == :show
  }
  self.authorize = lambda {
    Admin::ApiKeyPolicy.new(current_user, action.record).act_on?
  }
  self.message = lambda {
    "Change the name of API key #{record.name.inspect} (##{record.id})?"
  }
  self.confirm_button_label = "Change API Key Name"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(api_key)
      api_key.name = fields[:new_name]
      api_key.valid?

      return error(api_key.errors.full_messages_for(:name).to_sentence) if api_key.errors[:name].any?

      # API keys may be expired or soft-deleted by the time a privacy request is
      # handled. Only bypass those lifecycle validations for this name-only edit.
      api_key.update_attribute!(:name, api_key.name)

      succeed("API key ##{api_key.id} has been renamed to #{api_key.name.inspect}")
    end
  end
end
