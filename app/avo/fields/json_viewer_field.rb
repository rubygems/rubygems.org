class Avo::Fields::JsonViewerField < Avo::Fields::CodeField
  def initialize(name, **args, &)
    super(name, **args, language: :javascript, line_wrapping: true, &)
  end

  def value(...)
    super&.then { JSON.pretty_generate(it.as_json) }
  end
end
