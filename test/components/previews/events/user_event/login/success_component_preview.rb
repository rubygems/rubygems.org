class Events::UserEvent::Login::SuccessComponentPreview < Lookbook::Preview
  def password
    event = build_event(
      authentication_method: "password"
    )
    render Events::UserEvent::Login::SuccessComponent.new(event:)
  end

  def webauthn
    event = build_event(
      authentication_method: "webauthn",
      two_factor_label: "1Password"
    )
    render Events::UserEvent::Login::SuccessComponent.new(event:)
  end

  def password_with_otp
    event = build_event(
      authentication_method: "password",
      two_factor_method: "otp"
    )
    render Events::UserEvent::Login::SuccessComponent.new(event:)
  end

  private

  def build_event(**additional)
    FactoryBot.build(:events_user_event, tag: Events::UserEvent::LOGIN_SUCCESS, additional:)
  end
end
