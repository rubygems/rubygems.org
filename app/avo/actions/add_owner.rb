class AddOwner < BaseAction
  self.name = "Add owner"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  # https://rubygems_org.test/admin/avo_api/users/search?q=user1&global=false&via_association=belongs_to&via_association_id=owners&via_reflection_class=Rubygem&via_reflection_id=11&via_parent_resource_id=&via_parent_resource_class=&via_relation=
  field :owner, as: :select_record, searchable: true, name: "New owner", use_resource: UserResource

  self.message = lambda {
    "Are you sure you would like to add an owner to #{record.name}?"
  }

  self.confirm_button_label = "Add owner"

  class ActionHandler < ActionHandler
    set_callback :handle, :before do
      error "Must specify a valid user to add as owner" if @owner.blank?
    end

    set_callback :handle, :before do
      error "Cannot add #{@owner.name} as an owner since they are unconfirmed" if @owner.unconfirmed?
    end

    set_callback :handle_model, :before do
      @rubygem = current_model
      @owner = fields[:owner]
    end

    set_callback :handle_model, :before do
      error "Cannot add #{@owner.name} as an owner since they are already an owner of #{@rubygem.name}" if @owner.rubygems.include?(@rubygem)
    end

    def handle_model(rubygem)
      authorizer = User.find_by_email!("security@rubygems.org")
      rubygem.ownerships.create(user: @owner, authorizer: authorizer, confirmed_at: Time.current)
      succeed "Added #{@owner.name} to #{@rubygem.name}"
    end
  end
end
