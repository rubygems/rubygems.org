require 'test_helper'

class GemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
  end

  test "gem page with a non valid HTTP_ACCEPT header" do
    get rubygem_path(@rubygem), nil, {'HTTP_ACCEPT' => 'application/mercurial-0.1'}
    assert page.has_content? "1.0.0"
  end

  test "gems page with atom format" do
    get rubygems_path(format: :atom)
    assert_response :success
    assert_equal :atom, response.content_type.symbol
    assert page.has_content? "sandworm"
  end
end
