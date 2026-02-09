class Organization::Handle
  RESTFUL_ACTIONS = %w[
    create
    destroy
    edit
    index
    new
    show
    update
  ].freeze

  ROUTES = %w[
    admin
    api
    dashboard
    gems
    invitation
    invitations
    members
    memberships
    onboarding
    profile
    settings
    stats
    teams
    users
  ].freeze

  RESERVED = [
    *RESTFUL_ACTIONS,
    *ROUTES
  ].freeze

  def self.reserved?(handle)
    RESERVED.include?(handle.to_s.downcase)
  end
end
