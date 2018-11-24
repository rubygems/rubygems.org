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

  has_many :adoptions, dependent: :destroy
  has_many :ownerships, dependent: :destroy
  has_many :rubygems, through: :ownerships

  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_gems, -> { order("name ASC") }, through: :subscriptions, source: :rubygem

  has_many :deletions, dependent: :nullify
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

  enum mfa_level: { disabled: 0, ui_only: 1, ui_and_api: 2 }, _prefix: :mfa

  def self.authenticate(who, password)
    user = find_by(email: who.downcase) || find_by(handle: who)
    user if user&.authenticated?(password)
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
    self.token_expires_at = Time.zone.now + Gemcutter::EMAIL_TOKEN_EXPRIES_AFTER
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
    !mfa_disabled?
  end

  def disable_mfa!
    mfa_disabled!
    self.mfa_seed = ''
    self.mfa_recovery_codes = []
    save!(validate: false)
  end

  def verify_and_enable_mfa!(seed, level, otp, expiry)
    if expiry < Time.now.utc
      errors.add(:base, I18n.t('multifactor_auths.create.qrcode_expired'))
    elsif verify_digit_otp(seed, otp)
      enable_mfa!(seed, level)
    else
      errors.add(:base, I18n.t('multifactor_auths.incorrect_otp'))
    end
  end

  def enable_mfa!(seed, level)
    self.mfa_level = level
    self.mfa_seed = seed
    self.mfa_recovery_codes = Array.new(10).map { SecureRandom.hex(6) }
    save!(validate: false)
  end

  def mfa_api_authorized?(otp)
    return true unless mfa_ui_and_api?
    otp_verified?(otp)
  end

  def otp_verified?(otp)
    otp = otp.to_s
    return true if verify_digit_otp(mfa_seed, otp)

    return false unless mfa_recovery_codes.include? otp
    mfa_recovery_codes.delete(otp)
    save!(validate: false)
  end

  def can_cancel?(adoption)
    return true if adoption.user == self

    rubygem = Rubygem.find(adoption.rubygem_id)
    rubygem.owned_by?(self)
  end

  private

  def verify_digit_otp(seed, otp)
    totp = ROTP::TOTP.new(seed)
    return false unless totp.verify_with_drift_and_prior(otp, 30)

    save!(validate: false)
  end

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
