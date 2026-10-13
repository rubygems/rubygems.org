# frozen_string_literal: true

module AvoHelpers
  # Pass `at:` to sign in from the page under test: the login form redirects
  # back to it after OAuth, which skips rendering the admin home page.
  def avo_sign_in_as(user, at: nil)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "1",
      credentials: {
        token: user.oauth_token,
        expires: false
      },
      info: {
        name: user.login
      }
    )

    @ip_address = create(:ip_address, ip_address: "127.0.0.1")

    stub_github_info_request(user.info_data)

    visit at || avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
    return unless at

    assert_current_path at
    # Unlike `visit`, the OAuth redirect does not wait for Avo's JS handlers to attach.
    page.driver.with_playwright_page { |pw_page| pw_page.wait_for_load_state(state: "load") }
  end
end
