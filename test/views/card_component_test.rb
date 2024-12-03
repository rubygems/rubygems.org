require "test_helper"

class CardComponentTest < ComponentTest
  def render(...)
    response = super
    Capybara.string(response)
  end

  should "render a card with title, icon, and list content" do
    render CardComponent.new do |c|
      c.head("Gems", icon: "gems", count: 3)
      c.list do
        c.list_item_to("rubygem_version_path(1)") { "RubyGem1 (0.0.1)" }
        c.list_item_to("rubygem_version_path(2)") { "RubyGem2 (0.0.2)" }
        c.list_item_to("rubygem_version_path(3)") { "RubyGem3 (0.0.3)" }
      end
    end

    assert_selector "article"
    assert_selector "h3", text: "Gems"
    assert_selector "svg.fill-orange"
    assert_selector "span", text: "3"
    assert_link "RubyGem1 (0.0.1)", href: "rubygem_version_path(1)"
    assert_link "RubyGem2 (0.0.2)", href: "rubygem_version_path(2)"
    assert_link "RubyGem3 (0.0.3)", href: "rubygem_version_path(3)"
    refute_text "View all"
  end

  should "render a card with custom title and scrollable content" do
    render CardComponent.new do |c|
      c.head do
        c.title("History")
      end
      c.scrollable do
        "content"
      end
    end

    assert_selector "article"
    assert_selector "h3", text: "History"
    assert_text "content"
    refute_text "View all"
  end
end
