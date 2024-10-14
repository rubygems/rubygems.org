class Avo::Actions::DeleteWebhook < Avo::Actions::ApplicationAction
  self.name = "Delete Webhook"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to delete the webhook #{record.url} for #{record.what} (owned by #{record.user.name})?"
  }

  self.confirm_button_label = "Delete Webhook"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(webhook)
      webhook.destroy!
      WebHooksMailer.webhook_deleted(webhook.user_id, webhook.rubygem_id, webhook.url, webhook.failure_count).deliver_later
    end
  end
end
