class GlobalIdField < Avo::Fields::BelongsToField
  include SemanticLogger::Loggable

  delegate(*%i[values_for_type custom?], to: :@nil)

  def value
    super.find
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def view_component_name = "BelongsToField"

  def is_polymorphic? = true # rubocop:disable Naming/PredicateName
end
