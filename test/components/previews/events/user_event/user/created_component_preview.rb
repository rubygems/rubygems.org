class Events::UserEvent::User::CreatedComponentPreview < Lookbook::Preview
  # @param email email
  def default(email: "user@example.com")
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::CREATED, additional:
    {
      email:
    })
    render Events::UserEvent::User::CreatedComponent.new(
      event:
    )
  end
end
