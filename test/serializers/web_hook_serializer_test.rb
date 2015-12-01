require 'test_helper'

class WebHookSerializerTest < ActiveSupport::TestCase
  setup do
    @url     = "http://example.org"
    @user    = create(:user)
    @rubygem = create(:rubygem)
    @webhook = create(:web_hook, user: @user, rubygem: @rubygem, url: @url)
  end

  context 'JSON' do
    should 'have proper hash keys' do
      @serializer = WebHookSerializer.new(@webhook)
      @json_webhook = @serializer.attributes

      assert_equal(
        @json_webhook.keys,
        [:failure_count, :url]
      )
    end

    should 'display correct data' do
      @serializer = WebHookSerializer.new(@webhook)
      @json_webhook = @serializer.attributes

      assert_equal(
        @json_webhook,
        {
          url: @url,
          failure_count: @webhook.failure_count
        }
      )
    end
  end

  context 'XML' do
    should 'have proper hash keys' do
      @serializer = WebHookSerializer.new(@webhook)
      @xml_webhook = @serializer.to_xml

      xml = Nokogiri.parse(@xml_webhook)

      assert_equal %w(failure-count url), xml.root.children.select(&:element?).map(&:name).sort
    end

    should 'display correct data' do
      @serializer = WebHookSerializer.new(@webhook)
      @xml_webhook = @serializer.to_xml

      xml = Nokogiri.parse(@xml_webhook)

      assert_equal "web-hook", xml.root.name
      assert_equal %w(failure-count url), xml.root.children.select(&:element?).map(&:name).sort
      assert_equal @webhook.url, xml.at_css("url").content
      assert_equal @webhook.failure_count, xml.at_css("failure-count").content.to_i
    end
  end

  context 'YAML' do
    should 'have proper hash keys' do
      @serializer = WebHookSerializer.new(@webhook)
      @yaml_webhook = @serializer.to_yaml

      yaml = YAML.load(@yaml_webhook)

      assert_equal %w(failure_count url), yaml.keys.sort
    end

    should 'display correct data' do
      @serializer = WebHookSerializer.new(@webhook)
      @yaml_webhook = @serializer.to_yaml

      assert_equal(
        YAML.load(@yaml_webhook),
        {
          'url'           => @url,
          'failure_count' => @webhook.failure_count
        }
      )
    end
  end
end
