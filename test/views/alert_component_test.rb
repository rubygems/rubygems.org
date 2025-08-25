require "test_helper"

class AlertComponentTest < ComponentTest
  def alert(...)
    AlertComponent.new(...)
  end

  def render_page(component, &)
    response = render(component, &)
    Capybara.string(response)
  end

  test "renders a non-closable (blue) notice by default" do
    page = render_page(alert { "Hello, world!" })

    assert_selector ".bg-blue-200.text-neutral-800"
    assert_text page, "Hello, world!"
    refute_selector "button[title='Hide']"
  end

  test "renders a closable alert" do
    page = render_page(alert(style: :alert, closeable: true) { "Alert!" })

    assert_selector ".bg-yellow-200.text-neutral-800"
    assert_text page, "Alert!"
    assert_selector "button[title='Hide']"
  end

  test "renders a closable error" do
    page = render_page(alert(style: :error, closeable: true) { "Error!" })

    assert_selector ".bg-red-200.text-neutral-800"
    assert_text page, "Error!"
    assert_selector "button[title='Hide']"
  end

  test "renders a closable success" do
    page = render_page(alert(style: :success, closeable: true) { "Success!" })

    assert_selector ".bg-green-200.text-neutral-800"
    assert_text page, "Success!"
    assert_selector "button[title='Hide']"
  end

  test "renders a neutral alert" do
    page = render_page(alert(style: :neutral, closeable: false) { "Here's some info" })

    assert_selector ".bg-neutral-200.text-neutral-800"
    assert_text page, "Here's some info"
    refute_selector "button[title='Hide']"
  end
end
