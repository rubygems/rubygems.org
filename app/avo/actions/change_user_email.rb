class Avo::Actions::ChangeUserEmail < Avo::Actions::ApplicationAction
  def fields
    field :from_email, name: "Email", as: :text, required: true
    super
  end

  self.name = "Change User Email"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.confirm_button_label = "Change User Email"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      user.email = fields["from_email"]
      user.email_confirmed = false
      user.generate_confirmation_token

      return unless user.save!

      Mailer.email_confirmation(user).deliver_later
    end
  end
end
