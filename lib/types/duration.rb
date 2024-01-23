class Types::Duration < ActiveModel::Type::Value
  def cast_value(value)
    case value
    when NilClass, ActiveSupport::Duration
      value
    when String
      if /\A\d+\z/.match?(value)
        ActiveSupport::Duration.build(value.to_i)
      else
        ActiveSupport::Duration.parse(value)
      end
    when Integer
      ActiveSupport::Duration.build(value)
    else
      raise ArgumentError, "Cannot cast #{value.inspect} to a Duration"
    end
  rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
    nil
  end

  def serialize(duration)
    duration.presence&.iso8601
  end

  def type_cast_for_schema(value)
    serialize(value).inspect
  end
end
