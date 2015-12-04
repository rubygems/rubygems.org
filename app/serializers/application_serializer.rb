class ApplicationSerializer < ActiveModel::Serializer
  def to_xml(options = {})
    attributes.to_xml(options)
  end

  def to_yaml(*args)
    attrs = ActiveSupport::HashWithIndifferentAccess.new(attributes)
    attrs.to_yaml(*args)
  end
end
