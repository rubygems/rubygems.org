class GemValidator::YAMLGemspec
  def initialize(ast)
    @ast = ast
    @root = ast.children.first
  end

  def full_name
    "#{name}-#{version}"
  end

  def name
    @name ||= find_attribute(@root, "name").value
  end

  def version
    @version ||= find_attribute(find_attribute(@root, "version"), "version").value
  end

  def cert_chain
    @cert_chain ||= begin
      node = find_attribute(@root, "cert_chain")
      if node.nil? || node.scalar?
        []
      else
        node.children.map(&:value)
      end
    end
  end

  private

  def find_attribute(map, key)
    return nil unless map.respond_to?(:children)

    index = map.children.find_index { |child| child.scalar? && child.value == key }
    return unless index

    map.children[index + 1]
  end
end
