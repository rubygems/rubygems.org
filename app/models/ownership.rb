class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  belongs_to :authorizer, class_name: "User"
  has_many :api_key_rubygem_scopes, dependent: :destroy

  validates :user_id, uniqueness: { scope: :rubygem_id }

  delegate :name, to: :user, prefix: :owner
  delegate :name, to: :authorizer, prefix: true, allow_nil: true

  before_create :generate_confirmation_token

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def self.by_indexed_gem_name
    select("ownerships.*, rubygems.name")
      .left_joins(rubygem: :versions)
      .where(versions: { indexed: true })
      .distinct
      .order("rubygems.name ASC")
  end

  def self.find_by_owner_handle!(handle)
    joins(:user).find_by(users: { handle: handle }) || joins(:user).find_by!(users: { id: handle })
  end

  def self.create_confirmed(rubygem, user, approver)
    ownership = rubygem.ownerships.create(user: user, authorizer: approver)
    ownership.confirm!
  end

  def self.update_notifier(to_enable, to_disable, notifer_attr)
    where(id: to_enable).update_all(notifer_attr => true) if to_enable.any?
    where(id: to_disable).update_all(notifer_attr => false) if to_disable.any?
  end

  def self.update_push_notifier(to_enable_push, to_disable_push)
    update_notifier(to_enable_push, to_disable_push, "push_notifier")
  end

  def self.update_owner_notifier(to_enable_owner, to_disable_owner)
    update_notifier(to_enable_owner, to_disable_owner, "owner_notifier")
  end

  def self.update_ownership_request_notifier(to_enable_ownership_request, to_disable_ownership_request)
    update_notifier(to_enable_ownership_request, to_disable_ownership_request, "ownership_request_notifier")
  end

  def valid_confirmation_token?
    token_expires_at > Time.zone.now
  end

  def generate_confirmation_token
    self.token = SecureRandom.hex(20).encode("UTF-8")
    self.token_expires_at = Time.zone.now + Gemcutter::OWNERSHIP_TOKEN_EXPIRES_AFTER
  end

  def confirm!
    update(confirmed_at: Time.current, token: nil) if unconfirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    !confirmed?
  end

  def safe_destroy
    destroy if unconfirmed? || rubygem.owners.many?
  end
end
