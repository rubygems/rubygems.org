require 'test_helper'

class Internal::PingControllerTest < ActionController::TestCase
  context 'on GET to index' do
    setup do
      get :index
    end

    should respond_with :success

    should 'PONG' do
      assert page.has_content?('PONG')
    end
  end

  context 'with redis down' do
    should 'not PONG' do
      requires_toxiproxy
      Toxiproxy[:redis].down do
        assert_raises Redis::BaseError do
          get :index
        end
      end
    end
  end

  context 'with postgres down' do
    should 'not PONG' do
      ActiveRecord::Base.connection.stubs(:select_value).returns(nil)
      assert_raises StandardError do
        get :index
      end
    end
  end
end
