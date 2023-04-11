class ChangeEmail < BaseAction
  field :email, as: :text, required: true

  self.name = "Change Email"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.confirm_button_label = "Change Email"

  class ActionHandler < ActionHandler
    def handle_model(user)
      user.email = fields["email"]
      user.email_confirmed = false
      user.generate_confirmation_token

      return unless user.save
      Mailer.email_confirmation(user).deliver_later
    end
  end
end
