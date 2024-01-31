class Events::UserEvent::Email::VerifiedComponentPreview < Lookbook::Preview
  # @param email email
  def default(email: "user@example.com")
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::EMAIL_VERIFIED, additional:
    {
      email:
    })
    render Events::UserEvent::Email::VerifiedComponent.new(
      event:
    )
  end
end
