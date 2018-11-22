require 'test_helper'

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear

    @ip_address = "1.2.3.4"
    @user = create(:user, email: "nick@example.com", password: "secret12345")
  end

  def exceeding_limit
    (Rack::Attack::REQUEST_LIMIT * 1.25).to_i
  end

  def under_limit
    (Rack::Attack::REQUEST_LIMIT * 0.5).to_i
  end

  def limit_period
    Rack::Attack::LIMIT_PERIOD
  end

  def exceed_limit_for(scope)
    exceeding_limit.times do
      Rack::Attack.cache.count("#{scope}:#{@ip_address}", limit_period)
    end
  end

  def stay_under_limit_for(scope)
    under_limit.times do
      Rack::Attack.cache.count("#{scope}:#{@ip_address}", limit_period)
    end
  end

  def encode(username, password)
    ActionController::HttpAuthentication::Basic
      .encode_credentials(username, password)
  end

  context 'requests is lower than limit' do
    should 'allow sign in' do
      stay_under_limit_for("clearance/ip")

      post '/session',
        params: { session: { who: @user.email, password: @user.password } }
      follow_redirect!

      assert_response :success
    end

    should 'allow sign up' do
      stay_under_limit_for("clearance/ip")

      user = build(:user)
      post '/users',
        params: { user: { email: user.email, password: user.password } }
      follow_redirect!

      assert_response :success
    end

    should 'allow forgot password' do
      stay_under_limit_for("clearance/ip")
      under_limit = (Rack::Attack::PASSWORD_UPDATE_LIMIT * 0.25).to_i
      under_limit.times { Rack::Attack.cache.count("password/email:#{@email}", limit_period) }

      post '/passwords',
        params: { password: { email: @user.email } }

      assert_response :success
    end

    should 'allow api_key show' do
      stay_under_limit_for("api_key/ip")

      get '/api/v1/api_key.json',
        env: { 'HTTP_AUTHORIZATION' => encode(@user.handle, @user.password) }

      assert_response :success
    end

    context 'params' do
      should 'return 400 for bad request' do
        post '/session'

        assert_response :bad_request
      end

      should 'return 401 for unauthorized request' do
        post '/session', params: { session: { password: @user.password } }

        assert_response :unauthorized
      end
    end
  end

  context 'requests is higher than limit' do
    should 'throttle sign in' do
      exceed_limit_for("clearance/ip")

      post '/session',
        params: { session: { who: @user.email, password: @user.password } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should 'throttle sign up' do
      exceed_limit_for("clearance/ip")

      user = build(:user)
      post '/users',
        params: { user: { email: user.email, password: user.password } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should 'throttle forgot password' do
      exceed_limit_for("clearance/ip")

      post '/passwords',
        params: { password: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should 'throttle api_key show' do
      exceed_limit_for("api_key/ip")

      get '/api/v1/api_key.json',
        env: { 'HTTP_AUTHORIZATION' => encode(@user.handle, @user.password) },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile update" do
      cookies[:remember_token] = @user.remember_token

      exceed_limit_for("clearance/remember_token")
      patch "/profile",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile delete" do
      cookies[:remember_token] = @user.remember_token

      exceed_limit_for("clearance/remember_token")
      delete "/profile",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    context "password update" do
      should 'throttle by ip' do
        exceed_limit_for("clearance/ip")

        post '/passwords',
          params: { password: { email: @user.email } },
          headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end

      should "throttle by email" do
        exceed_limit = (Rack::Attack::PASSWORD_UPDATE_LIMIT * 1.25).to_i
        exceed_limit.times { Rack::Attack.cache.count("password/email:#{@user.email}", limit_period) }
        post '/passwords', params: { password: { email: @user.email } }

        assert_response :too_many_requests
      end
    end
  end
end
