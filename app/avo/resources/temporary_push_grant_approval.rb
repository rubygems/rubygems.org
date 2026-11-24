# frozen_string_literal: true

class Avo::Resources::TemporaryPushGrantApproval < Avo::BaseResource
  self.includes = %i[temporary_push_grant admin_github_user]

  def fields
    field :id, as: :id
    field :temporary_push_grant, as: :belongs_to
    field :admin_github_user, as: :belongs_to
    field :conflict_disclosure, as: :textarea
    field :scope_digest, as: :text
    field :created_at, as: :date_time
    field :updated_at, as: :date_time
  end
end
