class Avo::Fields::EventAdditionalField < Avo::Fields::BaseField
  def nested_field
    return unless record
    additional_type = record.additional_type
    if additional_type.nil?
      return JsonViewerField.new(id, **@args)
          .hydrate(record:, resource:, action:, view:, panel_name:, user:)
    end

    Avo::Fields::NestedField.new(id, **@args) do
      additional_type.attribute_types.each do |attribute_name, type|
        attribute_name = attribute_name.to_sym
        case type
        when Types::GlobalId
          field attribute_name, as: :global_id, show_on: :index
        when ActiveModel::Type::String
          field attribute_name, as: :text, show_on: :index
        when ActiveModel::Type::Boolean
          field attribute_name, as: :boolean, show_on: :index
        else
          field attribute_name, as: :text, hide_on: :index
        end
      end
    end.hydrate(record:, resource:, action:, view:, panel_name:, user:)
  end

  methods = %i[fill_field value update_using to_permitted_param component_for_view visible get_fields]
  methods.each do |method|
    define_method(method, &lambda do |*args, **kwargs|
      nf = nested_field
      nf ? nf.send(method, *args, **kwargs) : super(*args, **kwargs)
    end)
  end
end
