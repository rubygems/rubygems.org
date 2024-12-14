class AlertComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param content text "content"
  # @param style select "style", { choices: [notice, alert, error, success, primary, neutral] }
  # @param closeable toggle "closeable"
  def default(content = "Example content", style: :notice, closeable: false)
    render AlertComponent.new(style:, closeable:) do
      content
    end
  end
end
