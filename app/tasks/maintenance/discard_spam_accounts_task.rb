# frozen_string_literal: true

# Soft-deletes unconfirmed users with no gem ownerships matching an email domain.
#
# Parameters:
#   created_after:  Start of the time window (required)
#   created_before: End of the time window (defaults to now)
#   domain_suffix:  Email domain to match, e.g. "example.com"
class Maintenance::DiscardSpamAccountsTask < MaintenanceTasks::Task
  attribute :created_after, :datetime
  attribute :created_before, :datetime, default: -> { Time.current }
  attribute :domain_suffix, :string

  validates :created_after, presence: true
  validates :domain_suffix, presence: true

  def collection
    User.where("email LIKE ?", "%@#{ActiveRecord::Base.sanitize_sql_like(domain_suffix)}")
      .where(created_at: created_after..created_before)
      .where(email_confirmed: false)
      .where.missing(:ownerships)
  end

  def process(user)
    return if user.discarded?
    without_deletion_email { user.discard! }
  rescue ActiveRecord::ActiveRecordError, Discard::RecordNotDiscarded => e
    Rails.error.report(e, context: { user_id: user.id }, handled: true)
  end

  private

  def without_deletion_email
    User.skip_callback(:discard, :after, :send_deletion_complete_email)
    yield
  ensure
    User.set_callback(:discard, :after, :send_deletion_complete_email)
  end
end
