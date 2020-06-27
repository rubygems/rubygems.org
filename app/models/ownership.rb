class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  belongs_to :authorizer, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :rubygem_id }

  delegate :name, to: :user, prefix: :owner
  delegate :name, to: :authorizer, prefix: true

  before_create :generate_confirmation_token

  scope :confirmed, -> { where("confirmed_at IS NOT NULL") }
  scope :unconfirmed, ->(user) { where("confirmed_at IS NULL").where(user: user) }

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
    update(confirmed_at: Time.current)
  end

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    !confirmed?
  end

  def confirm_and_notify
    confirm_ownership! && notify_owner_added
  end

  def destroy_and_notify
    return false unless safe_destroy
    notify_owner_removed
  end

  private

  def safe_destroy
    destroy if unconfirmed? || rubygem.owners.many?
  end

  def notify_owner_removed
    OwnersMailer.delay.owner_removed(user_id, user_id, rubygem_id)
    rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.delay.owner_removed(user_id, notified_user.id, rubygem_id)
    end
  end

  def notify_owner_added
    rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.delay.owner_added(user_id, notified_user.id, rubygem_id)
    end
  end
end
