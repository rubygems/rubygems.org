require "test_helper"

class WebHookTest < ActiveSupport::TestCase
  should belong_to :user
  should belong_to(:rubygem).optional(true)

  should "be valid for normal hook" do
    hook = create(:web_hook)
    refute_predicate hook, :global?
    assert_empty WebHook.global
    assert_equal [hook], WebHook.specific
  end

  should "be valid for global hook" do
    hook = create(:global_web_hook)
    assert_nil hook.rubygem
    assert_predicate hook, :global?
    assert_equal [hook], WebHook.global
    assert_empty WebHook.specific
  end

  should "be invalid with url longer than maximum field length" do
    long_domain = "r" * (Gemcutter::MAX_FIELD_LENGTH + 1)
    hook = build(:web_hook, url: "https://#{long_domain}.com")
    refute_predicate hook, :valid?
    assert_equal(["is too long (maximum is 255 characters)"], hook.errors.messages[:url])
  end

  should "require user" do
    hook = build(:web_hook, user: nil)
    refute_predicate hook, :valid?
  end

  ["badurl", "", nil].each do |url|
    should "invalidate with #{url.inspect} as the url" do
      hook = build(:web_hook, url: url)
      refute_predicate hook, :valid?
    end
  end

  context "with a global webhook for a gem" do
    setup do
      @url     = "http://example.org"
      @user    = create(:user)
      @webhook = create(:global_web_hook, user: @user, url: @url)
    end

    should "not be able to create a webhook under this user, gem, and url" do
      webhook = WebHook.new(user: @user,
                            url: @url)
      refute_predicate webhook, :valid?
    end

    should "be able to create a webhook for a url under this user and gem" do
      webhook = WebHook.new(user: @user,
                            url: "http://example.net")
      assert_predicate webhook, :valid?
    end

    should "be able to create a webhook for another user under this url" do
      other_user = create(:user)
      webhook = WebHook.new(user: other_user,
                            url: @url)
      assert_predicate webhook, :valid?
    end
  end

  context "with a webhook for a gem" do
    setup do
      @url     = "http://example.org"
      @user    = create(:user)
      @rubygem = create(:rubygem)
      @webhook = create(:web_hook, user: @user, rubygem: @rubygem, url: @url)
    end

    should "show limited attributes for to_json" do
      assert_equal(
        {
          "url"           => @url,
          "failure_count" => @webhook.failure_count
        }, JSON.load(@webhook.to_json)
      )
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
          "url"           => @url,
          "failure_count" => @webhook.failure_count
        }, YAML.safe_load(@webhook.to_yaml)
      )
    end

    should "not be able to create a webhook under this user, gem, and url" do
      webhook = WebHook.new(user: @user,
                            rubygem: @rubygem,
                            url: @url)
      refute_predicate webhook, :valid?
    end

    should "be able to create a webhook for a url under this user and gem" do
      webhook = WebHook.new(user: @user,
                            rubygem: @rubygem,
                            url: "http://example.net")
      assert_predicate webhook, :valid?
    end

    should "be able to create a webhook for another rubygem under this user and url" do
      other_rubygem = create(:rubygem)
      webhook = WebHook.new(user: @user,
                            rubygem: other_rubygem,
                            url: @url)
      assert_predicate webhook, :valid?
    end

    should "be able to create a webhook for another user under this rubygem and url" do
      other_user = create(:user)
      webhook = WebHook.new(user: other_user,
                            rubygem: @rubygem,
                            url: @url)
      assert_predicate webhook, :valid?
    end

    should "be able to create a global webhook under this user and url" do
      webhook = WebHook.new(user: @user,
                            url: @url)
      assert_predicate webhook, :valid?
    end
  end

  context "with a non-global hook job" do
    setup do
      @url     = "http://example.com/gemcutter"
      @rubygem = create(:rubygem)
      @version = create(:version, rubygem: @rubygem)
      @hook    = create(:web_hook, rubygem: @rubygem, url: @url)
    end

    should "include an Authorization header" do
      authorization = Digest::SHA2.hexdigest(@rubygem.name + @version.number + @hook.user.api_key)
      RestClient::Request.expects(:execute).with(has_entries(headers: has_entries("Authorization" => authorization)))

      @hook.fire("https", "rubygems.org", @version)
    end

    should "include an Authorization header for a user with no API key" do
      @hook.user.update(api_key: nil)
      authorization = Digest::SHA2.hexdigest(@rubygem.name + @version.number)
      RestClient::Request.expects(:execute).with(has_entries(headers: has_entries("Authorization" => authorization)))

      @hook.fire("https", "rubygems.org", @version)
    end

    should "include an Authorization header for a user with many API keys" do
      @hook.user.update(api_key: nil)
      create(:api_key, user: @hook.user)
      authorization = Digest::SHA2.hexdigest(@rubygem.name + @version.number + @hook.user.api_keys.first.hashed_key)
      RestClient::Request.expects(:execute).with(has_entries(headers: has_entries("Authorization" => authorization)))

      @hook.fire("https", "rubygems.org", @version)
    end

    should "not increment failure count for hook" do
      @hook.fire("https", "rubygems.org", @version)

      assert_predicate @hook.failure_count, :zero?
    end
  end

  context "with invalid URL" do
    setup do
      @url     = "http://someinvaliddomain.com"
      @user    = create(:user)
      @rubygem = create(:rubygem)
      @version = create(:version, rubygem: @rubygem)
      @hook    = create(:global_web_hook, url: @url, user: @user)
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
        RestClient.stubs(:post).raises(exception)

        @hook.fire("https", "rubygems.org", @version)

        assert_equal index + 1, @hook.reload.failure_count
        assert_predicate @hook, :global?
      end
    end
  end

  context "yaml" do
    setup do
      @webhook = create(:web_hook)
    end

    should "return its payload" do
      assert_equal @webhook.payload, YAML.safe_load(@webhook.to_yaml)
    end

    should "nest properly" do
      assert_equal [@webhook.payload], YAML.safe_load([@webhook].to_yaml)
    end
  end
end
