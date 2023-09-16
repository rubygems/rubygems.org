require "test_helper"

class UsersControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "on GET to new" do
    setup do
      get :new
    end

    should render_template(:new)

    should "render the new user form" do
      page.assert_text "Sign up"
      page.assert_selector "input[type=password][autocomplete=new-password]"
    end
  end

  context "on POST to create" do
    context "when email and password are given" do
      should "create a user" do
        post :create, params: { user: { email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD } }

        assert User.find_by(email: "foo@bar.com")
      end
    end

    context "when missing a parameter" do
      should "raises parameter missing" do
        assert_no_changes -> { User.count } do
          post :create
        end
        assert_response :ok
        assert page.has_content?("Email address is not a valid email")
      end
    end

    context "when extra parameters given" do
      should "create a user if parameters are ok" do
        post :create, params: { user: { email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "foo", public_email: "true" } }

        user = User.find_by!(email: "foo@bar.com")

        assert_equal "foo", user.handle
        assert_predicate user, :public_email?
      end

      should "create a user but dont assign not valid parameters" do
        post :create, params: { user: { email: "foo@bar.com", password: "secret", api_key: "nonono" } }

        assert_not_equal "nonono", User.where(email: "foo@bar.com").pick(:api_key)
      end
    end

    context "confirmation mail" do
      setup do
        post :create, params: { user: { email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "foo" } }
      end

      should "set email_confirmation_token" do
        user = User.find_by_name("foo")

        assert_not_nil user.confirmation_token
      end

      should "deliver confirmation mail" do
        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

        refute_empty ActionMailer::Base.deliveries
        email = ActionMailer::Base.deliveries.last

        assert_equal ["foo@bar.com"], email.to
        assert_equal ["no-reply@mailer.rubygems.org"], email.from
        assert_equal "Please confirm your email address with RubyGems.org", email.subject
      end

      should "not deliver confirmation mail when token is removed meanwhile" do
        user = User.find_by_name("foo")
        user.update(confirmation_token: nil)

        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

        assert_empty ActionMailer::Base.deliveries
      end
    end
  end
end
