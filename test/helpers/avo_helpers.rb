module AvoHelpers
  def avo_sign_in_as(user)
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

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end
end
