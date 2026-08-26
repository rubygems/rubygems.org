# frozen_string_literal: true

require "test_helper"

class CopyFieldComponentTest < ComponentTest
  def render_page(component, &)
    response = render(component, &)
    Capybara.string(response)
  end

  should "render a readonly input with the value as the clipboard source" do
    render_page CopyFieldComponent.new(value: "gem install rails", name: "install_text")

    assert_selector "input[readonly][value='gem install rails']#install_text"
    assert_selector "input[data-clipboard-target='source']"
  end

  should "render a copy button wired to the clipboard controller" do
    render_page CopyFieldComponent.new(value: "gem install rails")

    assert_selector "[data-controller='clipboard'][data-clipboard-success-content-value='Copied!']"
    assert_selector "button[type='button'][data-action='click->clipboard#copy'][data-clipboard-target='button']"
    assert_selector "button[aria-label='Copy to clipboard'] svg"
  end

  should "render a label associated with the input when given" do
    render_page CopyFieldComponent.new(value: "gem 'rails'", name: "gemfile_text", label: "Gemfile")

    assert_selector "label[for='gemfile_text']", text: "Gemfile"
  end

  should "not render a label when none is given" do
    render_page CopyFieldComponent.new(value: "gem 'rails'")

    refute_selector "label"
  end

  should "label the input with aria-label when no visible label is given" do
    render_page CopyFieldComponent.new(value: "abc123", name: "checksum", aria_label: "SHA 256 checksum")

    assert_selector "input[aria-label='SHA 256 checksum']"
    refute_selector "label"
  end
end
