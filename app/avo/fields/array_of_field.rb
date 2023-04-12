class ArrayOfField < Avo::Fields::BaseField
  def initialize(name, field:, field_options: {}, **args, &block)
    super(name, **args, &nil)

    @make_field = ->(id:, index: nil, value: nil) do
      items_holder = Avo::ItemsHolder.new
      items_holder.field(id, name: index&.to_s || self.name, as: field, required: -> { false }, value:,  **field_options, &block)
      items_holder.items.sole.hydrate(view:, resource:)
    end
  end

  def value(...)
    case (value = super(...))
    when Hash
      value.values
    else
      Array.wrap(value)
    end
  end

  def template_member
    @make_field[id: "NEW_RECORD"]
  end

  def fill_field(model, key, value, params)
    value = value.each_value.map do |v|
      template_member.fill_field(NestedField::Holder.new(id), :item, v, params).item
    end
    # Rails.logger.warn("filling", id: id, value: value, vc: value.class)
    super(model, key, value, params)
  end

  def members
    value.each_with_index.map do |value, idx|
      id = "#{self.id}[#{idx}]"
      @make_field[id:, index: idx, value:]
    end
  end

  def to_permitted_param
    @make_field[id:].to_permitted_param
  end
end
