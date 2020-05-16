class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  validates :user_id, uniqueness: { scope: :rubygem_id }

  def self.by_indexed_gem_name
    select("ownerships.*, rubygems.name")
      .left_joins(rubygem: :versions)
      .where(versions: { indexed: true })
      .distinct
      .order("rubygems.name ASC")
  end

  def valid_confirmation_token?
    token_expires_at > Time.zone.now
  end

  def generate_confirmation_token
    self.token = SecureRandom.hex(20).encode("UTF-8")
    self.token_expires_at = Time.zone.now + Gemcutter::OWNERSHIP_TOKEN_EXPIRES_AFTER
  end

  def confirm_ownership!
    update(confirmed: true)
  end

  def notify_ownership_change(status)
    rubygem.notifiable_owners.each do |notified_user|
      Mailer.delay.owners_update(user_id, notified_user.id, status, rubygem_id)
    end
  end

  def safe_destroy
    rubygem.owners.many? && destroy
    Mailer.delay.owners_update(user_id, user_id, "removed", rubygem_id)
    notify_ownership_change("removed")
  end
end
