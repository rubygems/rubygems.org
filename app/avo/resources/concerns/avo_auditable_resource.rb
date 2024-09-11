module Avo::Resources::Concerns::AvoAuditableResource
  extend ActiveSupport::Concern

  def fetch_fields
    super
    return unless view.form?

    field :comment, as: :textarea, required: true,
          help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters."
  end

  # Would be nice if there was a way to force a field to show up as visible
  module HasItemsIncludeComment
    def visible_items
      items = super
      return items unless view.form? && items.none? { |item| item.id == :comment }

      comment = self.items.find { |item| item.id == :comment }
      return items unless comment
      items << comment
    end
  end
end
