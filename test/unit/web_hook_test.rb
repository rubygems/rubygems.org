require File.dirname(__FILE__) + '/../test_helper'

class WebHookTest < ActiveSupport::TestCase
  should belong_to :user
  should belong_to :rubygem

  should "be valid for normal hook" do
    hook = Factory(:web_hook)
    assert !hook.global?
    assert WebHook.global.empty?
    assert_equal [hook], WebHook.specific
  end

  should "be valid for global hook" do
    hook = Factory(:global_web_hook)
    assert_nil hook.rubygem
    assert hook.global?
    assert_equal [hook], WebHook.global
    assert WebHook.specific.empty?
  end

  should "require user" do
    hook = FactoryGirl.build(:web_hook, :user => nil)
    assert !hook.valid?
  end

  ["badurl", "", nil].each do |url|
    should "invalidate with #{url.inspect} as the url" do
      hook = FactoryGirl.build(:web_hook, :url => url)
      assert !hook.valid?
    end
  end

  context "with a global webhook for a gem" do
    setup do
      @url     = "http://example.org"
      @user    = Factory(:user)
      @webhook = Factory(:global_web_hook, :user    => @user,
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
      assert webhook.valid?
    end

    should "be able to create a webhook for another user under this url" do
      other_user = Factory(:user)
      webhook = WebHook.new(:user    => other_user,
                            :url     => @url)
      assert webhook.valid?
    end
  end

  context "with a webhook for a gem" do
    setup do
      @url     = "http://example.org"
      @user    = Factory(:user)
      @rubygem = Factory(:rubygem)
      @webhook = Factory(:web_hook, :user    => @user,
                                    :rubygem => @rubygem,
                                    :url     => @url)
    end

    should "show limited attributes for to_json" do
      assert_equal(
      {
        'url'           => @url,
        'failure_count' => @webhook.failure_count
      }, ActiveSupport::JSON.decode(@webhook.to_json))
    end

    should "show limited attributes for to_xml" do
      xml = Nokogiri.parse(@webhook.to_xml)

      assert_equal "web-hook", xml.root.name
      assert_equal %w[failure-count url], xml.root.children.select(&:element?).map(&:name).sort
      assert_equal @webhook.url, xml.at_css("url").content
      assert_equal @webhook.failure_count, xml.at_css("failure-count").content.to_i
    end

    should "show limited attributes for to_yaml" do
      assert_equal(
      {
        'url'           => @url,
        'failure_count' => @webhook.failure_count
      }, YAML.load(@webhook.to_yaml))
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
      assert webhook.valid?
    end

    should "be able to create a webhook for another rubygem under this user and url" do
      other_rubygem = Factory(:rubygem)
      webhook = WebHook.new(:user    => @user,
                            :rubygem => other_rubygem,
                            :url     => @url)
      assert webhook.valid?
    end

    should "be able to create a webhook for another user under this rubygem and url" do
      other_user = Factory(:user)
      webhook = WebHook.new(:user    => other_user,
                            :rubygem => @rubygem,
                            :url     => @url)
      assert webhook.valid?
    end

    should "be able to create a global webhook under this user and url" do
      webhook = WebHook.new(:user    => @user,
                            :url     => @url)
      assert webhook.valid?
    end
  end

  context "with a rubygem and version" do
    setup do
      @rubygem = Factory(:rubygem_with_downloads, :name => "foogem", :downloads => 42)
      @version = Factory(:version,
                         :rubygem           => @rubygem,
                         :number            => "3.2.1",
                         :authors           => %w[AUTHORS],
                         :description       => "DESC")
      @hook    = Factory(:web_hook)
      @job     = WebHookJob.new(@hook.url, 'localhost:1234', @rubygem, @version)
    end

    should "have gem properties encoded in JSON" do
      payload = ActiveSupport::JSON.decode(@job.payload)
      assert_equal "foogem",    payload['name']
      assert_equal "3.2.1",     payload['version']
      assert_equal "DESC",      payload["info"]
      assert_equal "AUTHORS",   payload["authors"]
      assert_equal 42,          payload["downloads"]
      assert_equal "http://localhost:1234/gems/foogem", payload['project_uri']
      assert_equal "http://localhost:1234/gems/foogem-3.2.1.gem", payload['gem_uri']
    end

    should "send the right version out even for older gems" do
      new_version = Factory(:version, :number => "2.0.0", :rubygem => @rubygem)
      new_hook    = Factory(:web_hook)
      job         = WebHookJob.new(new_hook.url, 'localhost:1234', @rubygem, new_version)
      payload     = ActiveSupport::JSON.decode(job.payload)

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
                         :url     => @url)
      stub_request(:post, @url)

      @hook.fire('rubygems.org', @rubygem, @version, false)
    end

    should "include an Authorization header" do
      request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
      authorization = Digest::SHA2.hexdigest(@rubygem.name + @version.number + @hook.user.api_key)

      assert_equal authorization, request.headers['Authorization']
    end

    should "not increment failure count for hook" do
      assert @hook.failure_count.zero?
    end
  end

  context "with invalid URL" do
    setup do
      @url     = 'http://someinvaliddomain.com'
      @user    = Factory(:user)
      @rubygem = Factory(:rubygem)
      @version = Factory(:version, :rubygem => @rubygem)
      @hook    = Factory(:global_web_hook, :url     => @url,
                                           :user    => @user)
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
        stub_request(:post, @url).to_raise(exception)

        @hook.fire('rubygems.org', @rubygem, @version, false)

        assert_equal index + 1, @hook.reload.failure_count
        assert @hook.global?
      end
    end
  end
end
