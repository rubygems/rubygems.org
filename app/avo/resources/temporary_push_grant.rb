# frozen_string_literal: true

class Avo::Resources::TemporaryPushGrant < Avo::BaseResource
  self.title = :id
  self.includes = %i[rubygem grantee]

  def actions
    action Avo::Actions::ApproveTemporaryPushGrant
    action Avo::Actions::RecordTemporaryPushGrantReview
    action Avo::Actions::ActivateTemporaryPushGrant
    action Avo::Actions::SuspendTemporaryPushGrant
    action Avo::Actions::ResumeTemporaryPushGrant
    action Avo::Actions::RevokeTemporaryPushGrant
  end

  def fields # rubocop:disable Metrics/MethodLength
    field :id, as: :id
    field :status, as: :badge, only_on: %i[index show],
      options: { success: %w[active completed], warning: %w[draft suspended], danger: %w[revoked expired] }
    field :rubygem, as: :belongs_to, searchable: true
    field :grantee, as: :belongs_to, use_resource: Avo::Resources::User, searchable: true,
      help: "Receives a publish-only API key. Never added as an owner or maintainer."
    field :original_grant, as: :belongs_to, use_resource: Avo::Resources::TemporaryPushGrant,
      help: "Only for the one corrective release linked to an original grant."
    field :correction_reason, as: :textarea, hide_on: :index
    field :version, as: :text
    field :source_commit, as: :text, hide_on: :index, help: "Full commit SHA the release is built from."
    field :request_url, as: :text, hide_on: :index,
      help: "The request issue in rubygems/temporary-push-access-log (or the advisory record for private requests)."
    field :justification, as: :textarea, hide_on: :index
    field :requester_github_login, as: :text, hide_on: :index
    field :grantee_github_login, as: :text, hide_on: :index
    field :outreach_sent_at, as: :date_time, hide_on: :index
    field :response_deadline_at, as: :date_time, hide_on: :index
    field :shortened_response_reason, as: :textarea, hide_on: :index,
      help: "Required when the deadline is under 14 days after outreach (active exploit only)."

    field :technical_reviewer, as: :text, readonly: true, only_on: :show
    field :technical_review_notes, as: :textarea, readonly: true, only_on: :show
    field :technical_reviewed_at, as: :date_time, readonly: true, only_on: :show
    field :activated_at, as: :date_time, readonly: true, only_on: %i[index show]
    field :expires_at, as: :date_time, readonly: true, only_on: %i[index show]
    field :suspended_at, as: :date_time, readonly: true, only_on: :show
    field :suspension_reason, as: :textarea, readonly: true, only_on: :show
    field :revoked_at, as: :date_time, readonly: true, only_on: :show
    field :revocation_reason, as: :textarea, readonly: true, only_on: :show
    field :api_key, as: :belongs_to, readonly: true, only_on: :show

    field :artifacts, as: :has_many
    field :approvals, as: :has_many
    field :audits, as: :has_many
  end
end
