class Events::UserEvent::Email::AddedComponentPreview < Lookbook::Preview
  # @param email email
  def default(email: "user@example.com")
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::EMAIL_ADDED, additional:
    {
      email:
    })
    render Events::UserEvent::Email::AddedComponent.new(
      event:
    )
  end
end
