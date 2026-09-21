# frozen_string_literal: true

require "test_helper"

class Rubygem::TabNavComponentTest < ComponentTest
  def render_page(component, &)
    response = render(component, &)
    Capybara.string(response)
  end

  def render_tabs(current: :gem_info)
    render_page Rubygem::TabNavComponent.new(current: current) do |nav|
      nav.disabled_tab("Readme", icon: "description")
      nav.tab("Gem info", "/gems/rails", icon: "info-i", name: :gem_info)
      nav.disabled_tab("Contents", icon: "folder-open")
      nav.tab("Dependencies", "/gems/rails/versions/1.0.0/dependencies", icon: "account-tree", name: :dependencies)
    end
  end

  should "render a nav with links and disabled stubs" do
    render_tabs

    assert_selector "nav[aria-label]"
    assert_link "Gem info", href: "/gems/rails"
    assert_link "Dependencies", href: "/gems/rails/versions/1.0.0/dependencies"
    refute_selector "a", text: "Readme"
    refute_selector "a", text: "Contents"
  end

  should "mark the current tab with aria-current and an underline" do
    render_tabs

    assert_selector "a[aria-current='page']", text: "Gem info"
    assert_selector "a.border-orange-500", text: "Gem info"
    refute_selector "a[aria-current='page']", text: "Dependencies"
  end

  should "mark disabled tabs with aria-disabled and no link" do
    render_tabs

    assert_selector "span[aria-disabled='true']", text: "Readme"
    assert_selector "span[aria-disabled='true']", text: "Contents"
  end
end
