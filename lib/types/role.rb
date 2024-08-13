class Types::Role < ActiveRecord::Type::Integer
  def cast(value)
    return nil if value.blank?
    value.to_s
  end

  def serialize(value)
    return nil if value.blank?
    Access.flag_for_role(value)
  end

  def deserialize(value)
    return nil if value.blank?
    Access.role_for_flag(value)
  end
end
