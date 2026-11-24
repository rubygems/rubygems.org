# frozen_string_literal: true

require "test_helper"

class FooterComponentTest < ComponentTest
  setup do
    render FooterComponent.new
  end

  test "renders Ruby Central as the operator" do
    operator = page.find("[data-testid='footer-operator']")

    assert_text operator, "Operated by"
    assert_logo_link operator, FooterComponent::OPERATOR
  end

  test "renders each tier with a heading and its supporters in order" do
    supporters = page.find("[data-testid='footer-supporters']")
    headings = supporters.all("h2").map(&:text)

    assert_equal ["Ruby Alliance", "RubyGems Supporters", "Infrastructure Donors"], headings

    FooterComponent::TIERS.each_value do |tier|
      tier.each { |supporter| assert_logo_link supporters, supporter }
    end

    labels = supporters.all("a[aria-label]").pluck(:"aria-label")
    expected = [FooterComponent::OPERATOR, *FooterComponent::TIERS.values.flatten].map(&:name)

    assert_equal expected, labels
  end

  test "links to the full supporters page" do
    assert_selector "a[href='/supporters']", text: "See all supporters"
  end

  test "a supporter must have a logo with a zero-origin view_box" do
    supporter = ->(icon, view_box) { FooterComponent::Supporter.new("Example", "https://example.com/", icon, view_box) }

    assert_raises(ArgumentError, match: /icon is required/) { supporter.call(nil, "0 0 100 40") }
    assert_raises(ArgumentError, match: /icon is required/) { supporter.call("", "0 0 100 40") }
    assert_raises(ArgumentError, match: /view_box must be/) { supporter.call("example-footer", nil) }
    assert_raises(ArgumentError, match: /view_box must be/) { supporter.call("example-footer", "40 40 86 80") }
    assert_equal "100.5", supporter.call("example-footer", "0 0 100.5 40").width
  end

  test "every supporter icon exists in the sprite with a matching size" do
    sprite = Nokogiri::XML(Rails.root.join("app/assets/images/icons.svg").read)

    [FooterComponent::OPERATOR, *FooterComponent::TIERS.values.flatten].each do |supporter|
      symbol = sprite.at_css("symbol##{supporter.icon}")

      refute_nil symbol, "missing #{supporter.icon} in icons.svg"
      assert_equal supporter.view_box.split.last(2), symbol["viewBox"].split.last(2),
        "#{supporter.icon} view_box size doesn't match its symbol"
    end
  end

  private

  def assert_logo_link(scope, supporter)
    link = scope.find("a[aria-label='#{supporter.name}']")

    assert_equal supporter.url, link[:href]

    svg = link.find("svg", visible: :all)

    assert_equal supporter.view_box, svg[:viewbox]
    assert_equal "aspect-ratio: #{supporter.width} / #{supporter.height}", svg[:style]
    assert svg.has_css?("use[href$='##{supporter.icon}']", visible: :all)
  end
end
