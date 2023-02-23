class DeleteWebhook < BaseAction
  self.name = "Delete Webhook"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to delete the webhook #{record.url} for #{record.what} (owned by #{record.user.name})?"
  }

  self.confirm_button_label = "Delete Webhook"

  class ActionHandler < ActionHandler
    def handle_model(webhook)
      webhook.destroy!
    end
  end
end
