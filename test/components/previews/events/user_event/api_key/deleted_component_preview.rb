class Events::UserEvent::ApiKey::DeletedComponentPreview < Lookbook::Preview
  # @param name text
  def default(name: "example")
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::API_KEY_DELETED, additional:
    {
      name:
    })
    render Events::UserEvent::ApiKey::DeletedComponent.new(
      event:
    )
  end
end
