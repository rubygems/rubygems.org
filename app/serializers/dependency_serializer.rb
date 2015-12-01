class DependencySerializer < ApplicationSerializer
  attributes :name, :requirements

  def to_xml(options = {})
    super(options.merge(root: 'dependency'))
  end
end
