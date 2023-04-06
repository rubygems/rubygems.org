class ModelAttributeField < Avo::Fields::HasOneField
  def frame_url
    # raise self.pretty_inspect
    Avo::Services::URIService.parse(@resource.record_path)
      .append_paths(id, model.id)
      .append_query(turbo_frame: turbo_frame)
      .to_s
  end

  define_method :component_for_view, Avo::Fields::BaseField.instance_method(:component_for_view)
end
