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

  context "with a rubygem and version" do
    setup do
      @rubygem = Factory(:rubygem,
                         :name      => "foogem",
                         :downloads => 42)
      @version = Factory(:version, 
                         :rubygem           => @rubygem,
                         :number            => "3.2.1", 
                         :rubyforge_project => "foogem-rf",
                         :authors           => "AUTHORS",
                         :description       => "DESC")
      @hook    = Factory(:web_hook,
                         :rubygem        => @rubygem,
                         :host_with_port => 'localhost:1234',
                         :version        => @version)
    end

    should "have gem properties encoded in JSON" do
      payload = ActiveSupport::JSON.decode(@hook.payload)
      assert_equal "foogem",    payload['name']
      assert_equal "3.2.1",     payload['version']
      assert_equal "foogem-rf", payload["rubyforge_project"]
      assert_equal "DESC",      payload["info"]
      assert_equal "AUTHORS",   payload["authors"]
      assert_equal 42,          payload["downloads"]
      assert_equal "http://localhost:1234/gems/foogem", payload['project_uri']
      assert_equal "http://localhost:1234/gems/foogem-3.2.1.gem", payload['gem_uri']
    end

    should "send the right version out even for older gems" do
      new_version = Factory(:version, :number => "2.0.0", :rubygem => @rubygem)
      new_hook    = Factory(:web_hook,
                            :rubygem        => @rubygem,
                            :host_with_port => 'localhost:1234',
                            :version        => new_version)
      payload = ActiveSupport::JSON.decode(new_hook.payload)
      
      assert_equal "foogem", payload['name']
      assert_equal "2.0.0",  payload['version']
      assert_equal "http://localhost:1234/gems/foogem", payload['project_uri']
      assert_equal "http://localhost:1234/gems/foogem-2.0.0.gem", payload['gem_uri']
    end
  end

  context "with a non-global hook job" do
    setup do 
      @url     = 'http://example.com/gemcutter'
      @rubygem = Factory(:rubygem)
      @version = Factory(:version, :rubygem => @rubygem)
      @hook    = Factory(:web_hook,
                         :rubygem => @rubygem,
                         :url     => @url,
                         :version => @version)
      WebMock.stub_request(:post, @url)
      @hook.perform
    end

    should "POST to URL with payload" do
      # Three assertions are used to more easily determine where failure occurs
      WebMock.assert_requested(:post, @url, 
                               :times => 1)
      WebMock.assert_requested(:post, @url, 
                               :body => @hook.payload)
      WebMock.assert_requested(:post, @url, 
                               :headers => { 'Content-Type' => 'application/json' })
    end

    should "not increment failure count for hook" do
      assert @hook.failure_count.zero?
    end
  end

  context "with invalid URL" do
    setup do
      @url     = 'http://someinvaliddomain.com'
      @user    = Factory(:email_confirmed_user)
      @rubygem = Factory(:rubygem)
      @version = Factory(:version, :rubygem => @rubygem)
      @hook    = Factory(:web_hook, :url     => @url,
                                    :rubygem => @rubygem,
                                    :user    => @user,
                                    :version => @version)
      @hook.host_with_port = 'example.org'
    end
    
    should "increment failure count for hook on errors" do
      [SocketError,
       Timeout::Error,
       Errno::EINVAL,
       Errno::ECONNRESET,
       EOFError,
       Net::HTTPBadResponse,
       Net::HTTPHeaderSyntaxError,
       Net::ProtocolError].each_with_index do |exception, index|
        WebMock.stub_request(:post, @url).to_raise(exception)
        @hook.perform
        assert_equal index + 1, @hook.failure_count
      end
    end
  end
end
