# frozen_string_literal: true

class OrganizationDomainVerificationJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "#{self.class.name}-#{arguments.first}" }
  )

  def perform(domain_id)
    domain = OrganizationDomain.find_by(id: domain_id)
    return if domain.nil?

    domain.verify!
  rescue OrganizationDomain::DeletedDomain
    nil
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    record_failure(domain, e)
  end

  private

  def record_failure(domain, error)
    return if domain.nil?

    message = "#{error.class}: #{error.message}".truncate(OrganizationDomainCheck::MAX_MESSAGE_LENGTH)
    domain.record_check!(outcome: "other_error", message:)
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    OrganizationDomain.where(id: domain.id).update_all(check_queued_at: nil)
  end
end
