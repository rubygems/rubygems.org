# frozen_string_literal: true

module SignInAssertions
  def assert_signed_in_as(user)
    flunk "Expected to be signed in as User #{user.handle.inspect}, but was not signed in." unless request.env[:clearance].signed_in?
    if request.env[:clearance].current_user != user
      current_user = request.env[:clearance].current_user

      flunk "Expected to be signed in as User: #{user.handle.inspect}\n" \
            "Actually signed in as User: #{current_user.handle.inspect}"
    end

    assert_equal user, request.env[:clearance].current_user
  end

  def refute_signed_in
    if request.env[:clearance].signed_in?
      current_user = request.env[:clearance].current_user

      flunk "Expected not to be signed in, but was signed in as User #{current_user.handle.inspect}"
    end

    assert_nil request.env[:clearance].current_user
  end

  # Asserts that the block's sign-in attempt is denied before any factor is verified,
  # so no recovery code is consumed and no WebAuthn sign count advances.
  def assert_mfa_sign_in_denied(user, credential: nil, &)
    user_state = user.reload.attributes
    credential_state = credential&.reload&.attributes

    assert_no_difference(-> { user.events.where(tag: Events::UserEvent::LOGIN_SUCCESS).count }, &)

    assert_response :unauthorized
    refute_signed_in
    assert_predicate cookies[:remember_token], :blank?
    assert_equal user_state, user.reload.attributes
    assert_equal credential_state, credential.reload.attributes if credential
  end
end
