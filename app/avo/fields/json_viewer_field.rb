class JsonViewerField < Avo::Fields::BaseField
  def initialize(name, **args, &)
    super(name, **args, &)
    @theme = args[:theme].present? ? args[:theme].to_s : "default"
    @height = args[:height].present? ? args[:height].to_s : "auto"
    @tab_size = args[:tab_size].presence || 2
    @indent_with_tabs = args[:indent_with_tabs].presence || false
    @line_wrapping = args[:line_wrapping].presence || true
  end

  attr_reader :height, :theme, :tab_size, :indent_with_tabs, :line_wrapping
end
