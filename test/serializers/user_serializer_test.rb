require "test_helper"

class UserSerializerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @serializable_user = UserSerializer.new(@user)
  end

  context "JSON" do
    setup do
      @json_user = JSON.parse(@serializable_user.to_json)
    end

    should "have id, handle and email" do
      expected_user = { "id" => @user.id, "handle" => @user.handle, "email" => @user.email }
      assert_equal expected_user, @json_user
    end
  end

  context "XML" do
    setup do
      @xml_user = Nokogiri.parse(@serializable_user.to_xml)
    end

    should "have id, handle and email" do
      assert_equal "user", @xml_user.root.name
      assert_equal %w(email handle id), @xml_user.root.children.select(&:element?).map(&:name).sort
      assert_equal @user.id, @xml_user.at_css("id").content.to_i
      assert_equal @user.handle, @xml_user.at_css("handle").content
      assert_equal @user.email, @xml_user.at_css("email").content
    end
  end

  context "YAML" do
    setup do
      @yaml_user = YAML.load(@serializable_user.to_yaml)
    end

    should "have id, handle and email" do
      expected_user = { "id" => @user.id, "handle" => @user.handle, "email" => @user.email }
      assert_equal expected_user, @yaml_user
    end
  end
end
