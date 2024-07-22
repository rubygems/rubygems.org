class Types::GlobalId < ActiveRecord::Type::String
  def cast_value(value) = value.nil? || value.is_a?(::GlobalID) ? super : ::GlobalID.parse(super)
  def deserialize(value) = cast_value(super)

  def type = :global_id
end
