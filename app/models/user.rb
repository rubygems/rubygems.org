class User < ApplicationRecord
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

  before_destroy :yank_gems

  has_many :ownerships, dependent: :destroy
  has_many :rubygems, through: :ownerships

  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_gems, -> { order("name ASC") }, through: :subscriptions, source: :rubygem

  has_many :deletions
  has_many :web_hooks, dependent: :destroy

  after_validation :set_unconfirmed_email, if: :email_changed?, on: :update
  before_create :generate_api_key, :generate_confirmation_token

  validates :email, length: { maximum: 254 }

  validates :handle, uniqueness: true, allow_nil: true
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
  validates :password, length: { within: 10..200 }, allow_nil: true, unless: :skip_password_validation?
  validate :unconfirmed_email_uniqueness

  enum mfa_level: { no_auth: 0, auth_only: 1, auth_and_write: 2 }

  def self.authenticate(who, password)
    user = find_by(email: who.downcase) || find_by(handle: who)
    user if user && user.authenticated?(password)
  end

  def self.find_by_slug!(slug)
    find_by(id: slug) || find_by!(handle: slug)
  end

  def self.find_by_name(name)
    find_by(email: name) || find_by(handle: name)
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
    payload.to_xml(options.merge(root: 'user'))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag = nil
    coder.implicit = true
    coder.map = payload
  end

  def set_unconfirmed_email
    self.attributes = { unconfirmed_email: email, email: email_was }
    generate_confirmation_token
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
    update_email! if unconfirmed_email
    update!(email_confirmed: true, confirmation_token: nil)
  end

  # confirmation token expires after 15 minutes
  def valid_confirmation_token?
    token_expires_at > Time.zone.now
  end

  def generate_confirmation_token
    self.confirmation_token = Clearance::Token.new
    self.token_expires_at = Time.zone.now + 15.minutes
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

  def mfa_enabled?
    self.no_auth?
  end

  def disable_mfa!
    self.no_auth!
    self.mfa_seed = ''
    self.mfa_recovery_codes = []
    save!(validate: false)
  end

  def self.generate_mfa
    [ROTP::Base32.random_base32, Array.new(10).map { SecureRandom.hex(6) }]
  end

  def enable_mfa!(seed, recovery, level)
    self.mfa_level = level
    self.mfa_seed = seed
    self.mfa_recovery_codes = recovery
    save!(validate: false)
  end

  def otp_verified?(otp)
    if mfa_enabled?
      true
    elsif self.mfa_recovery_codes.include?(otp)
      self.mfa_recovery_codes.delete(otp)
      save!(validate: false)
      true
    else
      otp == ROTP::TOTP.new(self.mfa_seed).now
    end
  end

  private

  def update_email!
    self.attributes = { email: unconfirmed_email, unconfirmed_email: nil }
    save!(validate: false)
  end

  def unconfirmed_email_uniqueness
    errors.add(:email, I18n.t('errors.messages.taken')) if unconfirmed_email_exists?
  end

  def unconfirmed_email_exists?
    User.where(unconfirmed_email: email).exists?
  end

  def yank_gems
    versions_to_yank = only_owner_gems.map(&:versions).flatten
    versions_to_yank.each do |v|
      deletions.create(version: v)
    end
  end
end
