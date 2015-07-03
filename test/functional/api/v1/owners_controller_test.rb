require 'test_helper'

class Api::V1::OwnersControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    should "route GET show with #{format.to_s.upcase}" do
      route = {controller: 'api/v1/owners',
               action:     'show',
               rubygem_id: "rails",
               format:     format.to_s}
      assert_recognizes(route, "/api/v1/gems/rails/owners.#{format}")
    end

    context "on GET to show with #{format.to_s.upcase}" do
      setup do
        @rubygem = create(:rubygem)
        @user = create(:user)
        @other_user = create(:user)
        @rubygem.ownerships.create(user: @user)

        @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        get :show, rubygem_id: @rubygem.to_param, format: format
      end

      should "return an array" do
        response = yield(@response.body)
        assert_kind_of Array, response
      end

      should "return correct owner email" do
        assert_equal @user.email, yield(@response.body)[0]['email']
      end

      should "return correct owner handle" do
        assert_equal @user.handle, yield(@response.body)[0]['handle']
      end

      should "not return other owner email" do
        assert yield(@response.body).map { |owner| owner['email'] }.exclude?(@other_user.email)
      end
    end
  end

  should_respond_to :json do |body|
    JSON.parse body
  end

  should_respond_to :yaml do |body|
    YAML.load body
  end

  context "on GET to owner gems with handle" do
    setup do
      @user = create(:user)
      get :gems, handle: @user.handle, format: :json
    end

    should respond_with :success
  end

  context "on GET to owner gems with id" do
    setup do
      @user = create(:user)
      get :gems, handle: @user.id, format: :json
    end

    should respond_with :success
  end

  should "route POST" do
    route = {controller: 'api/v1/owners',
             action:     'create',
             rubygem_id: "rails",
             format:     "json"}
    assert_recognizes(route, path: '/api/v1/gems/rails/owners.json', method: :post)
  end

  should "route DELETE" do
    route = {controller: 'api/v1/owners',
             action:     'destroy',
             rubygem_id: "rails",
             format:     "json"}
    assert_recognizes(route, path: '/api/v1/gems/rails/owners.json', method: :delete)
  end

  should "route GET gems" do
    route = {controller: 'api/v1/owners',
             action:       'gems',
             handle:       'example',
             format:       'json'}
    assert_recognizes(route, path: '/api/v1/owners/example/gems.json', method: :get)
  end

  should "return plain text 404 error" do
    @user = create(:user)
    @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    @request.accept = '*/*'
    post :create, rubygem_id: 'bananas'
    assert_equal 'This rubygem could not be found.', @response.body
  end

end
