class ResetApiKey < BaseAction
  self.name = "Reset Api Key"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to reset api key for #{record.handle} #{record.email}?"
  }
  self.confirm_button_label = "Reset Api Key"

  field :template, as: :select,
    options: {
      "Public Gem": :public_gem_reset_api_key,
      Honeycomb: :honeycomb_reset_api_key
    },
    help: "Select mailer template"

  class ActionHandler < ActionHandler
    def handle_model(user)
      user.reset_api_key!

      Mailer.reset_api_key(user, fields["template"]).deliver_later
    end
  end
end
