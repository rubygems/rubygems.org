class NestedField < Avo::Fields::BaseField
  attr_reader :fields

  include Avo::Concerns::HasFields

  def initialize(name, coercer: nil, stacked: true, **args, &block)
    @coercer = coercer
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
    # Rails.logger.warn(key:, value:, vc: value.class)
    value = value.to_h.to_h do |k, v|
      [k, get_field(k).fill_field(Holder.new("#{id}.#{k}"), :item, v, params).item]
    end
    value = @coercer.call(value) if @coercer
    super(model, key, value, params).tap do
      # Rails.logger.warn(model:, key:, value:, vc: value.class)
    end
  end

  def to_permitted_param
    { super => fields.map(&:to_permitted_param) }
  end

  class Holder
    attr_accessor :item

    def initialize(id)
      @id = id
    end

    attr_writer :item
  end
end
