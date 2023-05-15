class MergeUser < BaseAction
  field :mergeable_user, as: :select_record, searchable: true, name: "User to be merged", use_resource: UserResource

  self.name = "Merge User"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to merge this user to #{record.email}?"
  }

  self.confirm_button_label = "Merge User"

  class ActionHandler < ActionHandler
    set_callback :handle, :before do
      @mergeable_user = fields[:mergeable_user]
      error "Must specify a valid user to merge" if @mergeable_user.blank?
    end


    def handle_model(user)
      (@mergeable_user.rubygems - user.rubygems).each do |rubygem|
        ownership = rubygem.ownerships_including_unconfirmed.find_by_user_id(@mergeable_user.id)
        ownership.user = user
        ownership.save!
      end

      @mergeable_user.destroy!

      user.save!
    end
  end
end
