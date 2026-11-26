# frozen_string_literal: true

class FooterComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  def default
    render FooterComponent.new
  end
end
