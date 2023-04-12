class NestedField < Avo::Fields::BaseField
  attr_reader :fields

  include Avo::Concerns::HasFields

  def initialize(name, coercer: nil, **args, &block)
    @coercer = coercer
    @items_holder = Avo::ItemsHolder.new
    super(name, **args, &nil)
    instance_exec(&block) if block
  end

  def fields(**kwargs)
    @items_holder.items.grep Avo::Fields::BaseField
  end

  def field(name, **kwargs, &block)
    @items_holder.field("#{id}[#{name}]", name: name.to_s.humanize(keep_id_suffix: true), **kwargs, &block)
  end

  def fill_field(model, key, value, params)
    value = @coercer.call(value.to_h.compact_blank) if @coercer
    super(model, key, value, params).tap do
      get_fields.each do |field|
        attr_name = field.id[/\[([^\]]+)\]/, 1]
        v = value.send(attr_name)
        field.hydrate(model: v)
      end
      Rails.logger.warn(key:, value:, params:, attrs: get_fields.to_h { [_1.id, _1.model] })
    end
  end
end
