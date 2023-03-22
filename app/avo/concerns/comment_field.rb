module CommentField
  extend ActiveSupport::Concern

  included do
    field :comment, as: :textarea, required: true,
      help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters."
  end
end
