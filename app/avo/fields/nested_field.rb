# frozen_string_literal: true

class Avo::Fields::NestedField < Avo::Fields::BaseField
  include Avo::Concerns::HasItems

  def initialize(name, stacked: true, **args, &block)
    @items_holder = Avo::Resources::Items::Holder.new
    hide_on :index
    super(name, stacked:, **args, &nil)
    instance_exec(&block) if block
  end

  def fields(**_kwargs)
    @items_holder.instance_variable_get(:@items).grep Avo::Fields::BaseField
  end

  # `Avo::Concerns::HasItems#visible_items` only counts a held field as visible
  # on a form when its id is a setter on the record. A nested field's are setters
  # on the nested value, so without this every nested field is hidden on the
  # forms and, since Avo permits params only for updatable fields, dropped from
  # the update. Avo's chain minus that one check.
  def visible_items
    items.each { hydrate_item(it) }.select do |item|
      item.visible? &&
        (!item.respond_to?(:visible_in_view?) || item.visible_in_view?(view:)) &&
        (!item.respond_to?(:authorized?) || item.authorized?)
    end
  end

  delegate :field, to: :@items_holder

  def fill_field(model, key, value, params)
    value = value.to_h.to_h do |k, v|
      [k, get_field(k).fill_field(Holder.new, :item, v, params).item]
    end

    super
  end

  def to_permitted_param
    { super => fields.map(&:to_permitted_param) }
  end

  class Holder
    attr_accessor :item
  end
end
