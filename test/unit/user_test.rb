require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should_have_many :rubygems, :through => :ownerships
  should_have_many :ownerships
  should_have_many :subscribed_gems, :through => :subscriptions
  should_have_many :subscriptions
  should_have_many :web_hooks

  context "validations" do
    context "handle" do
      should "begin with a lowercase letter" do
        user = Factory.build(:user, :handle => "1abcde")
        assert_equal false, user.valid?
        assert_equal "is invalid", user.errors.on(:handle)

        user.handle = "abcdef"
        user.valid?
        assert_equal nil, user.errors.on(:handle)
      end

      should "contain only lowercase letters, numbers, dashes and underscores" do
        user = Factory.build(:user, :handle => "abc^%def")
        assert_equal false, user.valid?
        assert_equal "is invalid", user.errors.on(:handle)

        user.handle = "abc1_two-four"
        user.valid?
        assert_equal nil, user.errors.on(:handle)
      end

      should "be between 6 and 32 characters" do
        user = Factory.build(:user, :handle => "a")
        assert_equal false, user.valid?
        assert_equal "is too short (minimum is 6 characters)", user.errors.on(:handle)

        user.handle = "a" * 33
        assert_equal false, user.valid?
        assert_equal "is too long (maximum is 32 characters)", user.errors.on(:handle)

        user.handle = "abcdef"
        user.valid?
        assert_equal nil, user.errors.on(:handle)
      end

      should "be valid when blank" do
        user = Factory.build(:user, :handle => nil)
        user.valid?
        assert_equal nil, user.errors.on(:handle)
      end
    end
  end

  context "with a user" do
    setup do
      @user = Factory(:user, :handle => nil)
    end

    should "only have email when boiling down to json or yaml" do
      json = JSON.parse(@user.to_json)
      yaml = YAML.load(@user.to_yaml)

      hash = {"email" => @user.email}
      assert_equal hash, json
      assert_equal hash, yaml
    end

    should "create api key" do
      assert_not_nil @user.api_key
    end

    should "give email if handle is not set for name" do
      assert_nil @user.handle
      assert_equal @user.email, @user.name
    end

    should "give handle if handle is set for name" do
      @user.handle = "qrush"
      @user.save
      assert_equal @user.handle, @user.name
    end

    should "have a 32 character hexadecimal api key" do
      assert @user.api_key =~ /^[a-f0-9]{32}$/
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
    
    context "with a confirmed email address" do
      setup do
        @user = Factory(:email_confirmed_user)
        @user.confirmation_token = nil
        @user.save
      end
      
      should "generate a new confirmation token and set the email_changed token then the email gets changed" do
        assert_changed(@user, :confirmation_token) do
          @user.email_changed!
        end
        assert_equal true, @user.email_changed
      end
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

    should "have all gems and specific gems for hooks" do
      rubygem = Factory(:rubygem)
      rubygem_hook = Factory(:web_hook,
                             :user    => @user,
                             :rubygem => rubygem)
      global_hook  = Factory(:global_web_hook,
                             :user    => @user)

      all_hooks = @user.all_hooks

      assert_equal rubygem_hook, all_hooks[rubygem.name].first
      assert_equal global_hook, all_hooks["all gems"].first
    end

    should "have all gems for hooks" do
      global_hook  = Factory(:global_web_hook, :user => @user)
      all_hooks = @user.all_hooks

      assert_equal global_hook, all_hooks["all gems"].first
      assert_equal 1, all_hooks.keys.size
    end

    should "have only specific for hooks" do
      rubygem = Factory(:rubygem)
      rubygem_hook = Factory(:web_hook,
                             :user    => @user,
                             :rubygem => rubygem)
      all_hooks = @user.all_hooks

      assert_equal rubygem_hook, all_hooks[rubygem.name].first
      assert_equal 1, all_hooks.keys.size
    end
  end
end
