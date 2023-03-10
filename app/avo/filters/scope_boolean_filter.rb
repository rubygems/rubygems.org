class ScopeBooleanFilter < Avo::Filters::BooleanFilter
  def name
    arguments.fetch(:name) { self.class.to_s.demodulize.underscore.sub(/_filter$/, "").titleize }
  end

  def apply(_request, query, values)
    return query if default.each_key.all? { values[_1] }

    default.each_key.reduce(query.none) do |relation, scope|
      next relation unless values[scope]
      relation.or(query.send(scope))
    end
  end

  def default
    arguments[:default].stringify_keys
  end

  def options
    default.to_h { |k, _| [k, k.titleize] }
  end
end
