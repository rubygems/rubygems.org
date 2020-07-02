require "test_helper"

class UsersControllerTest < ActionController::TestCase
  include DelayedJobHelpers

  context "on GET to new" do
    setup do
      get :new
    end

    should redirect_to("sign up page") { sign_up_path }
  end

  context "on POST to create" do
    context "when email and password are given" do
      should "create a user" do
        post :create, params: {
          user: {
            email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD
          }
        }
        expected_job_classes = Set[Castle::RegistrationSucceeded, Delayed::PerformableMailer]

        assert User.find_by(email: "foo@bar.com")
        assert_equal expected_job_classes, queued_job_classes
      end
    end

    context "when email is taken" do
      should "not create a user" do
        create(:user, email: "foo@bar.com")
        post :create, params: {
          user: {
            email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD
          }
        }

        assert_equal User.where(email: "foo@bar.com").count, 1
        assert_equal Set[Castle::RegistrationFailed], queued_job_classes
      end
    end

    context "when missing a parameter" do
      should "raises parameter missing" do
        post :create

        assert_response :bad_request
        assert page.has_content?("Request is missing param 'user'")
        assert_equal Set[Castle::RegistrationFailed], queued_job_classes
      end
    end

    context "when extra parameters given" do
      should "create a user if parameters are ok" do
        post :create, params: {
          user: {
            email: "foo@bar.com",
            password: PasswordHelpers::SECURE_TEST_PASSWORD,
            handle: "foo"
          }
        }
        expected_job_classes = Set[Castle::RegistrationSucceeded, Delayed::PerformableMailer]

        assert_equal "foo", User.where(email: "foo@bar.com").pluck(:handle).first
        assert_equal expected_job_classes, queued_job_classes
      end

      should "create a user but dont assign not valid parameters" do
        post :create, params: {
          user: {
            email: "foo@bar.com", password: "secret", api_key: "nonono"
          }
        }
        assert_not_equal "nonono", User.where(email: "foo@bar.com").pluck(:api_key).first
      end
    end

    context "confirmation mail" do
      setup do
        post :create, params: {
          user: {
            email: "foo@bar.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "foo"
          }
        }
        Delayed::Worker.new.work_off
      end

      should "set email_confirmation_token" do
        user = User.find_by_name("foo")
        assert_not_nil user.confirmation_token
      end

      should "deliver confirmation mail" do
        refute ActionMailer::Base.deliveries.empty?
        email = ActionMailer::Base.deliveries.last
        assert_equal ["foo@bar.com"], email.to
        assert_equal ["no-reply@mailer.rubygems.org"], email.from
        assert_equal "Please confirm your email address with RubyGems.org", email.subject
      end
    end
  end
end
