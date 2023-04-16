class Types::JsonDeserializable < ActiveRecord::Type::Json
  def initialize(klass)
    @klass = klass
    super()
  end

  def cast_value(value) = value.nil? || value.is_a?(@klass) ? super : @klass.new(super)
  def deserialize(value) = cast_value(super)
end
