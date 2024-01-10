class Avo::Actions::CreateUser < Avo::Actions::ApplicationAction
  self.name = "Create User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index && !Rails.env.production?
  }
  self.standalone = true

  self.confirm_button_label = "Create User"

  def fields
    field :email, name: "Email", as: :text, required: true
  end

  class ActionHandler < ActionHandler
    def handle_standalone
      user = User.new(
        email: fields["email"],
        password: SecureRandom.hex(16),
        email_confirmed: true
      )
      user.generate_confirmation_token
      user.save!

      ::ClearanceMailer.change_password(user).deliver_later
      user
    end
  end
end
