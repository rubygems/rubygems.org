module Avo::Resources::Concerns::AvoAuditableResource
  extend ActiveSupport::Concern

  class_methods do
    def inherited(subclass)
      super

      subclass.concerning :AuditableFields, prepend: true do
        def fields # rubocop:disable Lint/NestedMethodDefinition
          raise "fields called"
          super

          panel "Auditable" do
            field :comment, as: :textarea, required: true,
              help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters.",
              only_on: %i[new edit]
          end
        end
      end
    end
  end
end
