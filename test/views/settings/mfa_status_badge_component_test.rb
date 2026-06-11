# frozen_string_literal: true

require "test_helper"

class Settings::MfaStatusBadgeComponentTest < ComponentTest
  def render_page(component)
    Capybara.string(render(component))
  end

  should "render an enabled badge" do
    page = render_page Settings::MfaStatusBadgeComponent.new(enabled: true)

    assert page.has_text?("Enabled")
    assert page.has_selector?("span.bg-green-100")
  end

  should "render a disabled badge" do
    page = render_page Settings::MfaStatusBadgeComponent.new(enabled: false)

    assert page.has_text?("Disabled")
    assert page.has_selector?("span.bg-neutral-200")
  end
end
