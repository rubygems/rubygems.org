class ButtonComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param text text "text"
  # @param url url "link"
  # @param type select "type", { choices: [button, link, submit] }
  # @param color select "color", { choices: [primary, secondary, red, orange, hammy, yellow, green, blue, neutral] }
  # @param size select "size", { choices: [small, large] }
  # @param style select "style", { choices: [fill, outline, plain] }
  # @param disabled toggle "disabled"
  def default(text: "Button", url: "", type: :button, color: :primary, size: :large, style: :fill, disabled: false) # rubocop:disable Metrics/ParameterLists
    args = [text, url].compact_blank
    render ButtonComponent.new(
      *args,
      type: type,
      color: color,
      size: size,
      style: style,
      disabled: disabled
    )
  end

  # @param text text "text"
  # @param url url "link"
  # @param type select "type", { choices: [button, link, submit] }
  # @param color select "color", { choices: [primary, secondary, red, orange, hammy, yellow, green, blue, neutral] }
  # @param size select "size", { choices: [small, large] }
  # @param style select "style", { choices: [fill, outline, plain] }
  # @param disabled toggle "disabled"
  def outline(text: "Button", url: "", type: :button, color: :primary, size: :large, style: :outline, disabled: false) # rubocop:disable Metrics/ParameterLists
    args = [text, url].compact_blank
    render ButtonComponent.new(
      *args,
      type: type,
      color: color,
      size: size,
      style: style,
      disabled: disabled
    )
  end

  # @param text text "text"
  # @param url url "link"
  # @param type select "type", { choices: [button, link, submit] }
  # @param color select "color", { choices: [primary, secondary, red, orange, hammy, yellow, green, blue, neutral] }
  # @param size select "size", { choices: [small, large] }
  # @param style select "style", { choices: [fill, outline, plain] }
  # @param disabled toggle "disabled"
  def plain(text: "Button", url: "", type: :button, color: :primary, size: :large, style: :plain, disabled: false) # rubocop:disable Metrics/ParameterLists
    args = [text, url].compact_blank
    render ButtonComponent.new(
      *args,
      type: type,
      color: color,
      size: size,
      style: style,
      disabled: disabled
    )
  end
end
