require 'test_helper'

class WebHookSerializerTest < ActiveSupport::TestCase
  setup do
    @url     = "http://example.org"
    @user    = create(:user)
    @rubygem = create(:rubygem, name: 'rubygem')
    @webhook = create(:web_hook, user: @user, rubygem: @rubygem, url: @url)
  end

  context 'JSON' do
    should 'have proper hash keys' do
      @serializer = WebHookSerializer.new(@user.web_hooks)
      @json_webhook = @serializer.attributes

      assert_equal(@json_webhook["rubygem"].first.keys, %w(failure_count url))
    end

    should 'display correct data' do
      @serializer = WebHookSerializer.new(@user.web_hooks)
      @json_webhook = @serializer.attributes

      assert_equal(
        @json_webhook["rubygem"],
        [{ "failure_count" => @webhook.failure_count, "url" => @url }]
      )
    end
  end

  context 'XML' do
    should 'have proper hash keys' do
      @serializer = WebHookSerializer.new(@user.web_hooks)
      @xml_webhook = @serializer.to_xml

      xml = Nokogiri.parse(@xml_webhook)

      keys = xml.css('rubygem rubygem').children.select(&:element?).map(&:name)
      assert_equal %w(failure-count url), keys
    end

    should 'display correct data' do
      @serializer = WebHookSerializer.new(@user.web_hooks)
      @xml_webhook = @serializer.to_xml

      xml = Nokogiri.parse(@xml_webhook)

      assert_equal "web-hook", xml.root.name
      assert_equal @webhook.url, xml.at_css("url").content
      assert_equal @webhook.failure_count, xml.at_css("failure-count").content.to_i
    end
  end

  context 'YAML' do
    should 'have proper hash keys' do
      @serializer = WebHookSerializer.new(@user.web_hooks)
      @yaml_webhook = @serializer.to_yaml

      yaml = YAML.load(@yaml_webhook)

      assert_equal %w(failure_count url), yaml["rubygem"].first.keys
    end

    should 'display correct data' do
      @serializer = WebHookSerializer.new(@user.web_hooks)
      @yaml_webhook = @serializer.to_yaml

      assert_equal(
        YAML.load(@yaml_webhook)["rubygem"],
        [{
          'url'           => @url,
          'failure_count' => @webhook.failure_count
        }]
      )
    end
  end
end
