# frozen_string_literal: true

require "test_helper"

class TooltipComponentTest < ComponentTest
  should "link the bubble to the trigger with aria-describedby" do
    render TooltipComponent.new(text: "Imported gem", id: "tip-1") { "*" }

    assert_selector "button[type='button'][aria-describedby='tip-1']", text: "*"
    assert_selector "span#tip-1[role='tooltip']", text: "Imported gem", visible: :all
  end

  should "render the trigger from markup returned by the block" do
    render TooltipComponent.new(text: "Imported gem") { view_context.tag.sup("*") }

    assert_selector "button sup", text: "*"
  end

  should "generate a unique id per instance" do
    ids = Array.new(3).map do
      render TooltipComponent.new(text: "hi") { "?" }
      page.first("[role='tooltip']", visible: :all)[:id]
    end

    assert_equal 3, ids.uniq.size
    assert(ids.all? { |id| id.start_with?("tooltip-") })
  end

  should "stay hidden until hover or keyboard focus" do
    render TooltipComponent.new(text: "hi") { "?" }

    bubble = page.first("[role='tooltip']", visible: :all)[:class]

    assert_includes bubble, "invisible"
    assert_includes bubble, "group-hover/tooltip:visible"
    assert_includes bubble, "group-focus-within/tooltip:visible"
  end

  should "name an icon-only trigger with the given label" do
    render TooltipComponent.new(text: "Requires MFA", trigger_label: "MFA") { "<svg></svg>" }

    assert_selector "button[aria-label='MFA'][aria-describedby]"
  end

  should "skip aria-label when the trigger has its own text" do
    render TooltipComponent.new(text: "Requires MFA") { "[?]" }

    refute_selector "button[aria-label]"
  end

  should "place the bubble above the trigger by default and below on request" do
    render TooltipComponent.new(text: "hi") { "?" }

    assert_includes page.first("[role='tooltip']", visible: :all)[:class], "bottom-full"

    render TooltipComponent.new(text: "hi", placement: :bottom) { "?" }

    assert_includes page.first("[role='tooltip']", visible: :all)[:class], "top-full"
  end

  should "raise on an unknown placement" do
    assert_raises(KeyError) do
      render TooltipComponent.new(text: "hi", placement: :sideways) { "?" }
    end
  end
end
