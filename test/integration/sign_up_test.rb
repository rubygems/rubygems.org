require "test_helper"

class SignUpTest < SystemTest
  test "sign up" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
    assert_equal Events::UserEvent::CreatedAdditional.new(email: "email@person.com"),
      User.find_by(handle: "nick").events.where(tag: Events::UserEvent::CREATED).sole.additional
  end

  test "sign up with no handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "errors prohibited"
  end

  test "sign up with bad handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "thisusernameiswaytoolongseriouslywaytoolong"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up with someone else's handle" do
    create(:user, handle: "nick")
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up when sign up is disabled" do
    Clearance.configure { |config| config.allow_sign_up = false }
    Rails.application.reload_routes!

    visit root_path

    refute page.has_content? "Sign up"
    assert_raises(ActionController::RoutingError) do
      visit "/sign_up"
    end
  end

  test "sign up when user param is string" do
    assert_nothing_raised do
      get "/sign_up?user=JJJ12QQQ"
    end
  end

  test "email confirmation" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Sign up"
    end

    link = last_email_link

    assert_not_nil link
    visit link

    assert page.has_content? "Sign out"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  teardown do
    Clearance.configure { |config| config.allow_sign_up = true }
    Rails.application.reload_routes!
  end
end
