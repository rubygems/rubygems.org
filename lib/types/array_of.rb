class Types::ArrayOf < ActiveModel::Type::Value
  def initialize(klass)
    @klass = klass
    super()
  end

  def type = :array_of

  def changed_in_place?(raw_old_value, new_value)
    deserialize(raw_old_value) != new_value
  end

  def cast_value(value)
    value&.map { member.cast(_1) }
  end

  def member = @klass.is_a?(Symbol) ? ActiveModel::Type.lookup(@klass) : @klass
end
