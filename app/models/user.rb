class User < ActiveRecord::Base
  include Clearance::User
  include Gravtastic
  is_gravtastic default: "retro"

  PERMITTED_ATTRS = [:bio, :email, :handle, :hide_email, :location, :password, :website]

  has_many :rubygems, through: :ownerships

  has_many :subscribed_gems, -> { order("name ASC") }, through: :subscriptions, source: :rubygem

  has_many :deletions
  has_many :ownerships
  has_many :subscriptions
  has_many :web_hooks

  before_validation :regenerate_token, if: :email_changed?, on: :update
  before_create :generate_api_key

  validates :handle, uniqueness: true, allow_nil: true
  validates :handle, format: {
    with: /\A[A-Za-z][A-Za-z_\-0-9]*\z/,
    message: "must start with a letter and can only contain letters, numbers, underscores, and dashes"
  }, allow_nil: true
  validates :handle, length: { within: 2..40 }, allow_nil: true

  def self.authenticate(who, password)
    if user = find_by(email: who.downcase) || find_by(handle: who)
      user if user.authenticated?(password)
    end
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

  def as_json(options = {})
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: 'user'))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag, coder.implicit, coder.map = nil, true, payload
  end

  def regenerate_token
    generate_confirmation_token
  end

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end

  def total_downloads_count
    rubygems.to_a.sum(&:downloads)
  end

  def today_downloads_count
    rubygems.to_a.sum(&:downloads_today)
  end

  def rubygems_downloaded
    rubygems.with_versions.sort_by { |rubygem| -rubygem.downloads }
  end

  def total_rubygems_count
    rubygems.with_versions.count
  end
end
