require "test_helper"

class UsersControllerTest < ActionController::TestCase
  context "on GET to new" do
    setup do
      get :new
    end

    render_template(:new)
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
        post :create, params: { user: { email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "foo" } }
        assert_equal "foo", User.where(email: "foo@bar.com").pick(:handle)
      end

      should "create a user but dont assign not valid parameters" do
        post :create, params: { user: { email: "foo@bar.com", password: "secret", api_key: "nonono" } }
        assert_not_equal "nonono", User.where(email: "foo@bar.com").pick(:api_key)
      end
    end

    context "confirmation mail" do
      setup do
        post :create, params: { user: { email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "foo" } }
        Delayed::Worker.new.work_off
      end

      should "set email_confirmation_token" do
        user = User.find_by_name("foo")
        assert_not_nil user.confirmation_token
      end

      should "deliver confirmation mail" do
        refute_empty ActionMailer::Base.deliveries
        email = ActionMailer::Base.deliveries.last
        assert_equal ["foo@bar.com"], email.to
        assert_equal ["no-reply@mailer.rubygems.org"], email.from
        assert_equal "Please confirm your email address with RubyGems.org", email.subject
      end
    end
  end
end
