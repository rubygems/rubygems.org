# frozen_string_literal: true

class CopyFieldComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param value text "value"
  # @param label text "label"
  def default(value: "gem 'rails', '~> 8.1'", label: "Gemfile")
    render CopyFieldComponent.new(value: value, label: label.presence, name: "preview_copy_field")
  end

  # @param value text "value"
  def without_label(value: "gem install rails")
    render CopyFieldComponent.new(value: value)
  end
end
