module ProfileHelpers
  def sign_in(user)
    visit sign_in_path
    fill_in "Email or Username", with: user.reload.email
    fill_in "Password", with: user.password
    click_button "Sign in"
  end
end
