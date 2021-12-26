module AdoptionHelpers
  def visit_rubygem_adoptions_path(rubygem, user)
    visit rubygem_adoptions_path(rubygem, as: user)
    return unless page.has_css? "#verify_password_password"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end
end
