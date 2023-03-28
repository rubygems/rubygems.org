class YankUser < BaseAction
  self.name = "Yank User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to yank user #{record.handle} #{record.email}?"
  }
  self.confirm_button_label = "Yank User"

  class ActionHandler < ActionHandler
    def handle_model(user)
      rubygems = user.rubygems
      security_user = User.find_by!(email: "security@rubygems.org")

      rubygems.find_each do |rubygem|
        rubygem.versions.each do |version|
          security_user.deletions.create!(version: version) unless version.yanked?
        end
      end

      user.block!
    end
  end
end
