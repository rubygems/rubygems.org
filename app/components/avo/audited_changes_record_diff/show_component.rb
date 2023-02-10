# frozen_string_literal: true

class Avo::AuditedChangesRecordDiff::ShowComponent < ViewComponent::Base
  def initialize(gid:, changes:, unchanged:, user:)
    super
    @gid = gid
    @changes = changes
    @unchanged = unchanged
    @user = user

    model = GlobalID::Locator.locate(gid)
    @resource = Avo::App.get_resource_by_name(model.class.name).hydrate(model:, user:)

    @old_resource = resource.dup.hydrate(model: resource.model.class.new(**unchanged, **changes.transform_values(&:first)))
    @new_resource = resource.dup.hydrate(model: resource.model.class.new(**unchanged, **changes.transform_values(&:last)))
  end

  attr_reader :gid, :changes, :unchanged, :user, :resource, :old_resource, :new_resource

  def each_field
    @resource.fields.each do |field|
      next if field.is_a?(Avo::Fields::HasBaseField)

      unless field.visible?
        if changes.key?(field.id.to_s)
          # dummy field to avoid ever printing out the contents... we just want the label
          yield :changed, Avo::Fields::IdField::ShowComponent.new(field: field)
        end
        next
      end

      if changes.key?(field.id.to_s)
        yield :new, field.component_for_view(:show).new(field: field.hydrate(model: new_resource.model), resource: new_resource)
        yield :old, field.component_for_view(:show).new(field: field.hydrate(model: old_resource.model), resource: old_resource)
      else
        yield :unchanged, field.component_for_view(:show).new(field: field.hydrate(model: new_resource.model), resource: new_resource)
      end
    end
  end

  def authorized?
    Pundit.policy!(user, resource.model).avo_show?
  end

  def title_link
    link_to(resource.model_title, resource.record_path)
  end

  def change_type_icon(type)
    case type
    when :changed
      helpers.svg("arrows-right-left", class: %w[h-4])
    when :new
      helpers.svg("forward", class: %w[h-4])
    when :old
      helpers.svg("backward", class: %w[h-4])
    end
  end

  def change_type_row_classes(type)
    case type
    when :changed
      %w[bg-orange-400]
    when :new
      %w[bg-green-400]
    when :old
      %w[bg-red-400]
    else []
    end + %w[flex flex-row items-baseline]
  end
end
