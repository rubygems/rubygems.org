require 'test_helper'

## SLOW TESTS ##
class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "nick@example.com", password: "secret123")
    @limit = 100
  end

  context 'requests is lower than limit' do
    should 'allow sign in' do
      10.times do
        post_via_redirect '/session', session: { who: @user.email, password: @user.password }
        assert_equal @response.status, 200
      end
    end

    should 'allow sign up' do
      10.times do
        user = build(:user)
        post_via_redirect '/users', user: { email: user.email, password: user.password }
        assert_equal @response.status, 200
      end
    end

    should 'allow forgot password' do
      10.times do
        post '/passwords', password: { email: @user.email }
        assert_equal @response.status, 200
      end
    end
  end

  context 'requests is higher than limit' do
    should 'throttle sign in' do
      (@limit + 1).times do |i|
        post_via_redirect '/session', session: { who: @user.email, password: @user.password }
        assert_equal @response.status, 429 if i > @limit
      end
    end

    should 'throttle sign up' do
      (@limit + 1).times do |i|
        user = build(:user)
        post_via_redirect '/users', user: { email: user.email, password: user.password }
        assert_equal @response.status, 429 if i > @limit
      end
    end

    should 'throttle forgot password' do
      (@limit + 1).times do |i|
        post '/passwords', password: { email: @user.email }
        assert_equal @response.status, 429 if i > @limit
      end
    end
  end
end
