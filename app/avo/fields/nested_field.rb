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

  # Avo hides a field that holds other fields when none of them are visible, and
  # on a form it only counts a held field as visible when its id is a setter on
  # the record (see `Avo::Concerns::HasItems#visible_items`). The fields held by
  # a nested field set attributes on the nested value, not on the record, so
  # that check hides every nested field on the new and edit forms -- and,
  # because Avo only permits params for the fields it considers updatable, it
  # silently drops the nested field from create and update as well. This is
  # `visible_items` without that one check.
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
