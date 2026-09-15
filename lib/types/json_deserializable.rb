# frozen_string_literal: true

class Types::JsonDeserializable < ActiveRecord::Type::Json
  def initialize(klass)
    @klass = klass
    super()
  end

  def cast_value(value) = value.nil? || value.is_a?(@klass) ? super : @klass.new(super)
  def deserialize(value) = cast_value(super)
  def serialize(value) = value.nil? ? super : super(normalize_for_json(value))

  private

  # Converts Array/Hash subclasses to plain types to prevent Rails 8.1's
  # JSONGemCoderEncoder from calling as_json on them, which would produce
  # unexpected structures (e.g., JSON::JWK::Set#as_json returns {keys: [...]})
  def normalize_for_json(value)
    case value
    when Hash
      value.to_h { |k, v| [k, normalize_for_json(v)] }
    when Array
      value.map { |v| normalize_for_json(v) }
    else
      value
    end
  end
end
