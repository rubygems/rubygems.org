require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    @version = create(:version, rubygem: @rubygem, number: "1.1.1")
  end

  test "subscribe to a gem" do
    visit subscriptions_path(as: @user.id)

    assert_text "You're not subscribed to any gems yet."

    visit rubygem_path(@rubygem.slug)

    click_link "Subscribe"

    assert_text "Unsubscribe"

    visit dashboard_path

    assert_text @rubygem.name
    assert_text @version.number

    visit subscriptions_path

    assert_text @rubygem.name

    page.find("button[title='Unsubscribe']").click # rubocop:disable Capybara/SpecificActions

    visit subscriptions_path

    assert_text "You're not subscribed to any gems yet."
  end
end
