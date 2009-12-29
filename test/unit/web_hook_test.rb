require File.dirname(__FILE__) + '/../test_helper'

class WebHookTest < ActiveSupport::TestCase
  should_belong_to :user
  should_belong_to :rubygem

  should "be valid for normal hook" do
    hook = Factory(:web_hook)
    assert !hook.global?
		assert WebHook.global.empty?
  end

  should "be valid for global hook" do
    hook = Factory(:global_web_hook)
    assert_nil hook.rubygem
    assert hook.global?
		assert_equal [hook], WebHook.global
  end

	should "require user" do
		hook = Factory.build(:web_hook, :user => nil)
		assert !hook.valid?
  end

  context "with a global webhook for a gem" do
    setup do
      @url     = "http://example.org"
      @user    = Factory(:email_confirmed_user)
      @webhook = Factory(:global_web_hook, :user    => @user,
                                           :rubygem => @rubygem,
                                           :url     => @url)
    end

    should "not be able to create a webhook under this user, gem, and url" do
      webhook = WebHook.new(:user    => @user,
                            :url     => @url)
      assert !webhook.valid?
    end

    should "be able to create a webhook for a url under this user and gem" do
      webhook = WebHook.new(:user    => @user,
                            :url     => "http://example.net")
      assert_valid webhook
    end

    should "be able to create a webhook for another user under this url" do
      other_user = Factory(:user)
      webhook = WebHook.new(:user    => other_user,
                            :url     => @url)
      assert_valid webhook
    end
  end

  context "with a webhook for a gem" do
    setup do
      @url     = "http://example.org"
      @user    = Factory(:email_confirmed_user)
      @rubygem = Factory(:rubygem)
      @webhook = Factory(:web_hook, :user    => @user,
                                    :rubygem => @rubygem,
                                    :url     => @url)
    end

    should "not be able to create a webhook under this user, gem, and url" do
      webhook = WebHook.new(:user    => @user,
                            :rubygem => @rubygem,
                            :url     => @url)
      assert !webhook.valid?
    end

    should "be able to create a webhook for a url under this user and gem" do
      webhook = WebHook.new(:user    => @user,
                            :rubygem => @rubygem,
                            :url     => "http://example.net")
      assert_valid webhook
    end

    should "be able to create a webhook for another rubygem under this user and url" do
      other_rubygem = Factory(:rubygem)
      webhook = WebHook.new(:user    => @user,
                            :rubygem => other_rubygem,
                            :url     => @url)
      assert_valid webhook
    end

    should "be able to create a webhook for another user under this rubygem and url" do
      other_user = Factory(:user)
      webhook = WebHook.new(:user    => other_user,
                            :rubygem => @rubygem,
                            :url     => @url)
      assert_valid webhook
    end
  end
end
