# frozen_string_literal: true

class Avo::Fields::JsonViewerField::ShowComponent < Avo::Fields::ShowComponent
  def pretty_json
    JSON.pretty_generate(@field.value)
  end
end
