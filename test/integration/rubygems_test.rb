require "test_helper"

class RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    create_list(:rubygem, 20) # rubocop:disable FactoryBot/ExcessiveCreateList
    create(:rubygem, name: "arrakis", number: "1.0.0")
  end

  test "gems list shows pagination" do
    get "/gems"

    assert page.has_content? "arrakis"
  end

  test "gems list doesn't fall pray to path_params query param" do
    get "/gems?path_params=string"

    assert page.has_content? "arrakis"
  end
end
