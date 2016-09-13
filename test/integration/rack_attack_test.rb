require 'test_helper'

## SLOW TESTS ##
class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "nick@example.com", password: "secret123")
    @limit = 100
  end

  def encode(username, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  context 'requests is lower than limit' do
    should 'allow sign in' do
      10.times do
        post_via_redirect '/session', session: { who: @user.email, password: @user.password }
        assert_equal 200, @response.status
      end
    end

    should 'allow sign up' do
      10.times do
        user = build(:user)
        post_via_redirect '/users', user: { email: user.email, password: user.password }
        assert_equal 200, @response.status
      end
    end

    should 'allow forgot password' do
      10.times do
        post '/passwords', password: { email: @user.email }
        assert_equal 200, @response.status
      end
    end

    should 'allow api_key show' do
      10.times do
        get '/api/v1/api_key.json', nil, 'HTTP_AUTHORIZATION' => encode(@user.handle, @user.password)
        assert_equal 200, @response.status
      end
    end

    context 'params' do
      should 'return 400 for bad request' do
        post_via_redirect '/session'
        assert_equal 400, @response.status
      end

      should 'return 401 for unauthorized request' do
        post_via_redirect '/session', session: { password: @user.password }
        assert_equal 401, @response.status
      end
    end
  end

  context 'requests is higher than limit' do
    should 'throttle sign in' do
      (@limit + 1).times do |i|
        post_via_redirect '/session', session: { who: @user.email, password: @user.password }
        assert_equal 429, @response.status if i > @limit
      end
    end

    should 'throttle sign up' do
      (@limit + 1).times do |i|
        user = build(:user)
        post_via_redirect '/users', user: { email: user.email, password: user.password }
        assert_equal 429, @response.status if i > @limit
      end
    end

    should 'throttle forgot password' do
      (@limit + 1).times do |i|
        post '/passwords', password: { email: @user.email }
        assert_equal 429, @response.status if i > @limit
      end
    end

    should 'throttle api_key show' do
      (@limit + 1).times do |i|
        get '/api/v1/api_key.json', nil, 'HTTP_AUTHORIZATION' => encode(@user.handle, @user.password)
        assert_equal 429, @response.status if i > @limit
      end
    end
  end
end
