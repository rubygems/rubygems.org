class NestedField < Avo::Fields::BaseField
  include Avo::Concerns::HasFields

  def initialize(name, stacked: true, **args, &block)
    @items_holder = Avo::ItemsHolder.new
    hide_on [:index]
    super(name, stacked:, **args, &nil)
    instance_exec(&block) if block
  end

  def fields(**_kwargs)
    @items_holder.items.grep Avo::Fields::BaseField
  end

  def field(name, **kwargs, &)
    @items_holder.field(name, **kwargs, &)
  end

  def fill_field(model, key, value, params)
    value = value.to_h.to_h do |k, v|
      [k, get_field(k).fill_field(Holder.new, :item, v, params).item]
    end

    super(model, key, value, params)
  end

  def to_permitted_param
    { super => fields.map(&:to_permitted_param) }
  end

  class Holder
    attr_accessor :item
  end
end
