require 'test_helper'

class UserSerializerTest < ActiveSupport::TestCase
  setup do
    @url     = "http://example.org"
    @user    = create(:user)
  end

  context 'JSON' do
    should 'have proper hash keys' do
      @serializer = UserSerializer.new(@user)
      @json_user = @serializer.attributes

      assert_equal(
        @json_user.keys,
        [:id, :email, :handle]
      )
    end

    should 'display correct data' do
      @serializer = UserSerializer.new(@user)
      @json_user = @serializer.attributes

      assert_equal(
        @json_user,
        {
          id: @user.id,
          email: @user.email,
          handle: @user.handle
        }
      )
    end
  end

  context 'XML' do
    should 'have proper hash keys' do
      @serializer = UserSerializer.new(@user)
      @xml_user = @serializer.to_xml

      xml = Nokogiri.parse(@xml_user)

      assert_equal %w(email handle id), xml.root.children.select(&:element?).map(&:name).sort
    end

    should 'display correct data' do
      @serializer = UserSerializer.new(@user)
      @xml_user = @serializer.to_xml

      xml = Nokogiri.parse(@xml_user)

      assert_equal "user", xml.root.name
      assert_equal %w(email handle id), xml.root.children.select(&:element?).map(&:name).sort
      assert_equal @user.id, xml.at_css("id").content.to_i
      assert_equal @user.email, xml.at_css("email").content
      assert_equal @user.handle, xml.at_css("handle").content
    end
  end

  context 'YAML' do
    should 'have proper hash keys' do
      @serializer = UserSerializer.new(@user)
      @yaml_user = @serializer.to_yaml

      yaml = YAML.load(@yaml_user)

      assert_equal %w(email handle id), yaml.keys.sort
    end

    should 'display correct data' do
      @serializer = UserSerializer.new(@user)
      @yaml_user = @serializer.to_yaml

      assert_equal(
        YAML.load(@yaml_user),
        {
          "id" => @user.id,
          "email" => @user.email,
          'handle' => @user.handle
        }
      )
    end
  end
end
