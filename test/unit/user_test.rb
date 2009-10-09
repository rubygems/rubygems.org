require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should_have_many :rubygems, :through => :ownerships
  should_have_many :ownerships
  should_have_many :subscribed_gems, :through => :subscriptions
  should_have_many :subscriptions

  context "with a user" do
    setup do
      @user = Factory(:user)
    end

    should "create api key" do
      assert_not_nil @user.api_key
    end
    
    should "reset api key" do
      assert_changed(@user, :api_key) do
        @user.reset_api_key!
      end
    end

    should "only return approved rubygems" do
      my_rubygem = Factory(:rubygem)
      other_rubygem = Factory(:rubygem)
      Factory(:ownership, :user => @user, :rubygem => my_rubygem, :approved => true)
      Factory(:ownership, :user => @user, :rubygem => other_rubygem, :approved => false)

      assert_equal [my_rubygem], @user.rubygems
    end

    context "with subscribed gems" do
      setup do
        @subscribed_gem   = Factory(:rubygem)
        @unsubscribed_gem = Factory(:rubygem)
        Factory(:subscription, :user => @user, :rubygem => @subscribed_gem)
      end

      should "only fetch the subscribed gems with #subscribed_gems" do
        assert_contains         @user.subscribed_gems, @subscribed_gem
        assert_does_not_contain @user.subscribed_gems, @unsubscribed_gem
      end
    end

    context "with the rubyforge user set up" do
      setup do
        ENV["RUBYFORGE_IMPORTER"] = "42"
      end

      should "be true if rubyforge user is pushing to us" do
        stub(@user).id { ENV["RUBYFORGE_IMPORTER"] }
        assert @user.rubyforge_importer?
      end

      should "be false if it's not the rubyforge user" do
        assert ! @user.rubyforge_importer?
      end

      teardown do
        ENV["RUBYFORGE_USER"] = nil
      end
    end
  end
end
