class JsonDeserializable < ActiveRecord::Type::Json
  def initialize(klass)
    @klass = klass
    super()
  end

  def deserialize(value) = @klass.new(super)
end
