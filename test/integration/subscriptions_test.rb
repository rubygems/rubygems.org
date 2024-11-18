require "test_helper"

class SubscriptionsTest < SystemTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    @version = create(:version, rubygem: @rubygem, number: "1.1.1")
  end

  test "subscribe to a gem" do
    visit subscriptions_path(as: @user.id)

    assert page.has_content? "You're not subscribed to any gems yet."

    visit rubygem_path(@rubygem.slug)

    click_link "Subscribe"

    assert page.has_content? "Unsubscribe"

    visit dashboard_path

    assert page.has_content? @rubygem.name
    assert page.has_content? @version.number

    visit subscriptions_path

    assert page.has_content? @rubygem.name

    page.find("button[title='Unsubscribe']").click # rubocop:disable Capybara/SpecificActions

    visit subscriptions_path

    assert page.has_content? "You're not subscribed to any gems yet."
  end
end
