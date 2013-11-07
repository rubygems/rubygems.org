require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @rubygems_count = 1337
      @downloads_count = 1_000_000
      stub(Rubygem).total_count { @rubygems_count }
      stub(Rubygem).latest { [] }
      stub(Download).most_downloaded_today { [] }
      stub(Version).just_updated { [] }
      stub(Download).count { @downloads_count }
      get :index
      pending
    end

    should respond_with :success
    should render_template :index

    should "display counts" do
      assert page.has_content?("1,337")
      assert page.has_content?("1,000,000")
    end

    should "load up the total count, latest, and most downloaded gems" do
      assert_received(Rubygem)  { |subject| subject.total_count }
      assert_received(Rubygem)  { |subject| subject.latest }
      assert_received(Download) { |subject| subject.most_downloaded_today }
      assert_received(Version)  { |subject| subject.just_updated }
      assert_received(Download) { |subject| subject.count }
    end
  end

  context "on GET to index with a non-ssl request when not signed in" do
    setup do
      @request.env["rack.url_scheme"] = "http"
      get :index
    end

    should "not redirect to the SSL path" do
      assert_template 'index'
    end

    should "contain HTTPS links to sign in and sign up" do
      assert_select "a[href=?]", sign_in_url(:protocol   => 'https')
      assert_select "a[href=?]", sign_up_url(:protocol   => 'https')
    end

  end

  context "on GET to index with a non-ssl request when signed in" do
    setup do
      cookies[:ssl] = true
      @request.env["rack.url_scheme"] = "http"
      get :index
    end

    should "redirect to the SSL path" do
      assert_redirected_to "https://#{@request.host}#{@request.fullpath}"
    end
  end

end
