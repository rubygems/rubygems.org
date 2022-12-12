class User < ApplicationRecord
  include UserMultifactorMethods
  include UserWebauthnMethods
  include Clearance::User
  include Gravtastic
  is_gravtastic default: "retro"

  PERMITTED_ATTRS = %i[
    bio
    email
    handle
    hide_email
    location
    password
    website
    twitter_username
  ].freeze

  before_save :_generate_confirmation_token_no_reset_unconfirmed_email, if: :will_save_change_to_unconfirmed_email?
  before_create :_generate_confirmation_token_no_reset_unconfirmed_email
  before_destroy :yank_gems

  has_many :ownerships, -> { confirmed }, dependent: :destroy, inverse_of: :user

  has_many :rubygems, through: :ownerships, source: :rubygem
  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_gems, -> { order("name ASC") }, through: :subscriptions, source: :rubygem

  has_many :deletions, dependent: :nullify
  has_many :web_hooks, dependent: :destroy

  # used for deleting unconfirmed ownerships as well on user destroy
  has_many :unconfirmed_ownerships, -> { unconfirmed }, dependent: :destroy, inverse_of: :user, class_name: "Ownership"
  has_many :api_keys, dependent: :destroy

  has_many :ownership_calls, -> { opened }, dependent: :destroy, inverse_of: :user
  has_many :ownership_requests, -> { opened }, dependent: :destroy, inverse_of: :user

  validates :email, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true
  validates :unconfirmed_email, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  validates :handle, uniqueness: { case_sensitive: false }, allow_nil: true, if: :handle_changed?
  validates :handle, format: {
    with: /\A[A-Za-z][A-Za-z_\-0-9]*\z/,
    message: "must start with a letter and can only contain letters, numbers, underscores, and dashes"
  }, allow_nil: true
  validates :handle, length: { within: 2..40 }, allow_nil: true

  validates :twitter_username, format: {
    with: /\A[a-zA-Z0-9_]*\z/,
    message: "can only contain letters, numbers, and underscores"
  }, allow_nil: true

  validates :twitter_username, length: { within: 0..20 }, allow_nil: true
  validates :password,
    length: { within: 10..200 },
    unpwn: true,
    allow_nil: true,
    unless: :skip_password_validation?
  validate :unconfirmed_email_uniqueness
  validate :toxic_email_domain, on: :create

  def self.authenticate(who, password)
    user = find_by(email: who.downcase) || find_by(handle: who)
    user if user&.authenticated?(password)
  rescue BCrypt::Errors::InvalidHash
    nil
  end

  def self.find_by_slug!(slug)
    raise ActiveRecord::RecordNotFound if slug.blank?
    find_by(id: slug) || find_by!(handle: slug)
  end

  def self.find_by_slug(slug)
    return if slug.blank?
    find_by(id: slug) || find_by(handle: slug)
  end

  def self.find_by_name(name)
    return if name.blank?
    find_by(email: name) || find_by(handle: name)
  end

  def self.find_by_blocked(slug)
    return if slug.blank?
    find_by(blocked_email: slug) || find_by(handle: slug)
  end

  def self.push_notifiable_owners
    where(ownerships: { push_notifier: true })
  end

  def self.ownership_notifiable_owners
    where(ownerships: { owner_notifier: true })
  end

  def self.ownership_request_notifiable_owners
    where(ownerships: { ownership_request_notifier: true })
  end

  def name
    handle || email
  end

  def display_handle
    handle || "##{id}"
  end

  def display_id
    handle || id
  end

  def reset_api_key!
    generate_api_key && save!
  end

  def all_hooks
    all     = web_hooks.specific.group_by { |hook| hook.rubygem.name }
    globals = web_hooks.global.to_a
    all["all gems"] = globals if globals.present?
    all
  end

  def payload
    attrs = { "id" => id, "handle" => handle }
    attrs["email"] = email unless hide_email
    attrs
  end

  def as_json(*)
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: "user"))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag = nil
    coder.implicit = true
    coder.map = payload
  end

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end

  def total_downloads_count
    rubygems.to_a.sum(&:downloads)
  end

  def rubygems_downloaded
    rubygems.with_versions.sort_by { |rubygem| -rubygem.downloads }
  end

  def total_rubygems_count
    rubygems.with_versions.count
  end

  def confirm_email!
    return false if unconfirmed_email && !update_email
    update!(email_confirmed: true, confirmation_token: nil)
  end

  # confirmation token expires after 15 minutes
  def valid_confirmation_token?
    token_expires_at > Time.zone.now
  end

  def generate_confirmation_token(reset_unconfirmed_email: true)
    self.unconfirmed_email = nil if reset_unconfirmed_email
    self.confirmation_token = Clearance::Token.new
    self.token_expires_at = Time.zone.now + Gemcutter::EMAIL_TOKEN_EXPRIES_AFTER
  end

  def _generate_confirmation_token_no_reset_unconfirmed_email
    generate_confirmation_token(reset_unconfirmed_email: false)
  end

  def unconfirmed?
    !email_confirmed
  end

  def only_owner_gems
    rubygems.with_versions.where('rubygems.id IN (
      SELECT rubygem_id FROM ownerships GROUP BY rubygem_id HAVING count(rubygem_id) = 1)')
  end

  def remember_me!
    self.remember_token = Clearance::Token.new
    self.remember_token_expires_at = Gemcutter::REMEMBER_FOR.from_now
    save!(validate: false)
    remember_token
  end

  def remember_me?
    remember_token_expires_at && remember_token_expires_at > Time.zone.now
  end

  def block!
    original_email = email
    transaction do
      update_attribute(:email, "security+locked-#{SecureRandom.hex(4)}-#{display_handle.downcase}@rubygems.org")
      confirm_email!
      disable_mfa!
      update_attribute(:password, SecureRandom.alphanumeric)
      update!(
        remember_token: nil,
        remember_token_expires_at: nil,
        api_key: nil,
        blocked_email: original_email
      )
      api_keys.delete_all
    end
  end

  def can_request_ownership?(rubygem)
    !rubygem.owned_by?(self) && rubygem.ownership_requestable?
  end

  private

  def update_email
    self.attributes = { email: unconfirmed_email, unconfirmed_email: nil, mail_fails: 0 }
    save
  end

  def unconfirmed_email_uniqueness
    errors.add(:email, I18n.t("errors.messages.taken")) if unconfirmed_email_exists?
  end

  def unconfirmed_email_exists?
    User.exists?(email: unconfirmed_email)
  end

  def yank_gems
    versions_to_yank = only_owner_gems.map(&:versions).flatten
    versions_to_yank.each do |v|
      deletions.create(version: v)
    end
  end

  def toxic_email_domain
    return unless (domain = email.split("@").last)
    toxic_domains_path = Pathname.new(Gemcutter::Application.config.toxic_domains_filepath)
    toxic = toxic_domains_path.exist? && toxic_domains_path.readlines.grep(/^#{Regexp.escape(domain)}$/).any?

    errors.add(:email, I18n.t("activerecord.errors.messages.blocked", domain: domain)) if toxic
  end
end
