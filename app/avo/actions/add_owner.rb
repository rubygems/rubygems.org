class Avo::Actions::AddOwner < Avo::Actions::ApplicationAction
  self.name = "Add owner"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  def fields
    field :owner, as: :select_record, searchable: true, name: "New owner", use_resource: Avo::Resources::User
  end

  self.message = lambda {
    "Are you sure you would like to add an owner to #{record.name}?"
  }

  self.confirm_button_label = "Add owner"

  class ActionHandler < ActionHandler
    set_callback :handle, :before do
      @owner = fields[:owner]
      error "Must specify a valid user to add as owner" if @owner.blank?
    end

    set_callback :handle, :before do
      error "Cannot add #{@owner.name} as an owner since they are unconfirmed" if @owner.unconfirmed?
    end

    def do_handle_record(rubygem)
      @rubygem = rubygem
      super
    end

    set_callback :handle_record, :before do
      error "Cannot add #{@owner.name} as an owner since they are already an owner of #{@rubygem.name}" if @owner.rubygems.include?(@rubygem)
    end

    def handle_record(rubygem)
      authorizer = User.security_user
      rubygem.ownerships.create!(user: @owner, authorizer: authorizer, confirmed_at: Time.current)
      succeed "Added #{@owner.name} to #{@rubygem.name}"
    end
  end
end
