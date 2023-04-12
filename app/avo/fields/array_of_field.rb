class ArrayOfField < Avo::Fields::BaseField
  def initialize(name, field:, field_options: {}, **args, &block)
    super(name, **args, &nil)

    @make_field = ->(id:) do
      items_holder = Avo::ItemsHolder.new
      items_holder.field(id, name: self.name, as: field, **field_options, &block)
      items_holder.items.sole
    end
  end

  def values
    Array.wrap(value)
  end

  def template_member
    @make_field[id: "#{id}[NEW_RECORD]"].hydrate(view:, resource:)
  end
end
