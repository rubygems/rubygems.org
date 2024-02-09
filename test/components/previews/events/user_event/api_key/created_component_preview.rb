class Events::UserEvent::ApiKey::CreatedComponentPreview < Lookbook::Preview
  # @param name text
  # @param scopes [Array<String>]
  # @param mfa toggle
  # @param gem text
  def default(name: "example", scopes: ["push"], mfa: false, gem: nil)
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::API_KEY_CREATED, additional:
    {
      name:,
      scopes:,
      mfa:,
      gem: gem.presence
    })
    render Events::UserEvent::ApiKey::CreatedComponent.new(
      event:
    )
  end
end
