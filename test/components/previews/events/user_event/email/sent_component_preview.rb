class Events::UserEvent::Email::SentComponentPreview < Lookbook::Preview
  # @param subject text
  # @param from email
  # @param to email
  def default(subject: "[Subject]", from: "example@rubygems.org", to: "user@example.com")
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::EMAIL_SENT, additional:
    {
      subject:,
      from:,
      to:
    })
    render Events::UserEvent::Email::SentComponent.new(
      event:
    )
  end
end
