require 'test_helper'

class OauthTest < SystemTest

  setup do
    ensure_site_host_setup
    # Create admin user
    @user = create(:user, email: "nick@example.com", password: "secret123", handle: "nick1")
    # Sign in user
    sign_in
  end

  test "admin users may create applications" do
    # Give current user admin rights
    refute ACL.admin?(@user)
    ENV['ADMIN_USERS'] = "#{@user.handle}=#{@user.email}"
    ACL.load_admin_users!
    assert ACL.admin?(@user)

    oauth_path = url_helpers.new_oauth_application_path
    params = {}
    full_path = build_path(oauth_path, params)
    visit full_path

    assert_equal request.path, oauth_path

    app = Doorkeeper::Application.find_by(name: "New App")
    assert_equal app, nil
    form = find("#new_doorkeeper_application")
    within form do
      fill_in "doorkeeper_application[name]", with: "New App"
      fill_in "doorkeeper_application[redirect_uri]", with: "urn:ietf:wg:oauth:2.0:oob"
      click_button "Submit"
    end

    assert_equal response.status, 200
    app = Doorkeeper::Application.find_by(name: "New App")
    refute_equal app, nil

    assert_equal find("div.alert").text, I18n.t("doorkeeper.flash.applications.create")[:notice]
    assert_equal find("code#application_id").text, app.uid
    assert_equal find("code#secret").text, app.secret
    assert page.has_content?(app.redirect_uri)
  end

  test "non-admin users may not create applications" do
    # Ensure current user lacks admin rights
    ENV['ADMIN_USERS'] = ""
    ACL.load_admin_users!
    refute ACL.admin?(@user)

    oauth_path = url_helpers.new_oauth_application_path
    params = {}
    full_path = build_path(oauth_path, params)

    assert_raise Doorkeeper::Errors::DoorkeeperError do
      visit full_path
    end
  end

  private

  def sign_in
    visit sign_in_path
    fill_in "Email or Handle", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def url_helpers
    @url_helpers ||= Rails.application.routes.url_helpers
  end

  def build_query_params(params)
    Rack::Utils.build_query(params)
  end

  # Will blow up if any input doesn't reduce to a string
  def build_path(path, params)
    path + "?" + build_query_params(params)
  end

  def request
    page.driver.request
  end

  def response
    page.driver.response
  end

  # TODO: move to config/environments/test.rb
  def ensure_site_host_setup
    @site_host = "localhost:3000"
    @site_host = Rails.application.routes.default_url_options[:host] ||= @site_host
  end
end
