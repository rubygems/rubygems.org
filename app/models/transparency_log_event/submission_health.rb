# frozen_string_literal: true

# Reports Rekor submission backlog state for transparency log events.
TransparencyLogEvent::SubmissionHealth = Data.define(:relation) do
  def oldest_pending_event
    relation.pending_submission.first
  end

  def latest_submitted_event
    relation.submitted_to_rekor.order(rekor_submitted_at: :desc, id: :desc).first
  end

  def pending_submission_count
    relation.pending_submission.count
  end

  def submission_lag(now: Time.current)
    return 0.seconds unless (event = oldest_pending_event)

    now - event.created_at
  end
end
