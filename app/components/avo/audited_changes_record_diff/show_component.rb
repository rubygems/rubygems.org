# frozen_string_literal: true

class Avo::AuditedChangesRecordDiff::ShowComponent < ViewComponent::Base
  def initialize(gid:, changes:, unchanged:, view:, user:)
    super
    @gid = gid
    @changes = changes
    @unchanged = unchanged
    @user = user
    @view = view

    global_id = GlobalID.parse(gid)
    resource_class = Avo.resource_manager.get_resource_by_model_class(global_id.model_class)
    unless resource_class
      logger.info "No avo resource class for #{global_id} found"
      return
    end

    record = begin
      global_id.find
    rescue ActiveRecord::RecordNotFound
      global_id.model_class.new(id: global_id.model_id)
    end
    @resource = resource_class.new(record:, view:, user:).detect_fields

    @old_resource = resource_class
      .new(record: resource.model_class.new(**unchanged, **changes.transform_values(&:first)), view:, user:).detect_fields
    @new_resource = resource_class
      .new(record: resource.model_class.new(**unchanged, **changes.transform_values(&:last)), view:, user:).detect_fields
  end

  def render?
    @resource.present?
  end

  attr_reader :gid, :changes, :unchanged, :user, :resource, :old_resource, :new_resource, :view

  def sorted_fields
    @resource.only_fields
      .reject { _1.is_a?(Avo::Fields::HasBaseField) }
      .sort_by.with_index { |f, i| [changes.key?(f.id.to_s) ? -1 : 1, i] }
  end

  def each_field # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    deleted = changes.key?("id") && changes.dig("id", 1).nil?
    new_record = changes.key?("id") && changes.dig("id", 0).nil?

    sorted_fields.each do |field|
      database_id = field.database_id&.to_s || "#{field.id}_id"

      unless field.visible?
        if changes.key?(database_id)
          # dummy field to avoid ever printing out the contents... we just want the label
          yield (deleted ? :old : :changed), Avo::Fields::BooleanField::ShowComponent.new(field: field)
        end
        next
      end

      if changes.key?(database_id)
        yield :new, component_for_field(field, new_resource) unless deleted
        yield :old, component_for_field(field, old_resource) unless new_record
      elsif unchanged.key?(database_id)
        yield :unchanged, component_for_field(field, new_resource)
      end
    end
  end

  def component_for_field(field, resource)
    field = field.hydrate(resource:, record: resource.record, view:, user:)
    field.component_for_view(view).new(field:, resource:)
  end

  def authorized?
    Pundit.policy!(user, [:admin, resource.record]).avo_show?
  end

  def title_link
    link_to(resource.record_title, resource.record_path)
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
      %w[bg-green-500]
    when :old
      %w[bg-red-400]
    else []
    end + %w[flex flex-row items-baseline]
  end
end
