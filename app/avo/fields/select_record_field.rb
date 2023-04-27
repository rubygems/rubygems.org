class SelectRecordField < Avo::Fields::BelongsToField
  def foreign_key
    id
  end

  def resolve_attribute(value)
    return if value.blank?
    target_resource.find_record value
  end
end
