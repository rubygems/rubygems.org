class Avo::Fields::SelectRecordField < Avo::Fields::BelongsToField
  def foreign_key
    id
  end

  def resolve_attribute(value)
    return if value.blank?
    target_resource.find_record value
  end

  def form_field_label
    is_searchable? ? id : super
  end
end
