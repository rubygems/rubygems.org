module Concerns::AvoAuditableResource
  extend ActiveSupport::Concern

  class_methods do
    def inherited(base)
      super
      base.items_holder = Avo::ItemsHolder.new
      base.items_holder.items.replace items_holder.items.deep_dup
      base.items_holder.invalid_fields.replace items_holder.invalid_fields.deep_dup
    end
  end

  included do
    panel "Auditable" do
      field :comment, as: :textarea, required: true,
        help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters.",
        only_on: %i[new edit]
    end
  end
end
