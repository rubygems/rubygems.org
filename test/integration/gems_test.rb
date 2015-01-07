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

  test "subscribe to a gem" do
    get rubygem_path(@rubygem, as: @user.id)
    assert page.has_css?('a#subscribe')

    post rubygem_subscription_path(@rubygem, as: @user.id), nil, {'HTTP_ACCEPT' => 'application/javascript'}

    assert_match(/\("\.toggler"\)\.toggle\(\)/, @response.body)
    assert_equal @user.subscribed_gems.first, @rubygem
  end

  test "unsubscribe to a gem" do
    create(:subscription, rubygem: @rubygem, user: @user)

    get rubygem_path(@rubygem, as: @user.id)
    assert page.has_css?('a#unsubscribe')

    delete rubygem_subscription_path(@rubygem, as: @user.id), nil, {'HTTP_ACCEPT' => 'application/javascript'}
    assert_match(/\("\.toggler"\)\.toggle\(\)/, @response.body)
  end
end
