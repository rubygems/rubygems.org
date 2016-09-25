require 'test_helper'

class EmailConfirmationTest < SystemTest
  setup do
    @user = create(:user)
  end

  def request_confirmation_mail(email)
    visit sign_in_path

    click_link "Didn't receive confirmation mail?"
    fill_in 'Email address', with: email
    click_button 'Resend Confirmation'
  end

  test 'requesting confirmation mail does not tell if a user exists' do
    request_confirmation_mail 'someone@example.com'

    assert page.has_content? 'We will email you confirmation link to activate your account if one exists.'
  end

  test 'requesting confirmation mail with email of existing user' do
    request_confirmation_mail @user.email

    Delayed::Worker.new.work_off
    body = ActionMailer::Base.deliveries.last.to_s
    link = /href="([^"]*)"/.match(body)
    assert_not_nil link[1]

    visit link[1]

    assert page.has_content? 'Sign out'
    assert page.has_selector? '#flash_notice', text: 'Your email address have been verified'
  end
end
