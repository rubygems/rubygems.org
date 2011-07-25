class User < ActiveRecord::Base
  include Clearance::User
  include Gravtastic
  is_gravtastic :default => "retro"

  attr_accessible :bio, :email, :handle, :location, :password,
                  :password_confirmation, :website

  has_many :rubygems, :through    => :ownerships,
                      :conditions => { 'ownerships.approved' => true }

  has_many :subscribed_gems, :through => :subscriptions,
                             :source  => :rubygem,
                             :order   => "name ASC"
  has_many :ownerships
  has_many :subscriptions
  has_many :web_hooks

  before_validation :regenerate_token, :if => :email_changed?, :on => :update
  before_create :generate_api_key
  after_update :deliver_email_reset, :if => :email_reset

  validates_uniqueness_of :handle, :allow_nil => true
  validates_format_of :handle, :with => /\A[A-Za-z][A-Za-z_\-0-9]*\z/, :allow_nil => true
  validates_length_of :handle, :within => 3..15, :allow_nil => true

  def self.authenticate(who, password)
    if user = Rubyforger.transfer(who, password) || find_by_email(who) || find_by_handle(who)
      user if user.authenticated?(password)
    end
  end

  def self.find_by_slug!(slug)
    find_by_id(slug) || find_by_handle!(slug)
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

  def rubyforge_importer?
    id.to_s == ENV["RUBYFORGE_IMPORTER"]
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

  def as_json(options={})
    {'email' => email}
  end

  def to_xml(options={})
    {'email' => email}.to_xml(options.merge(:root => 'user'))
  end

  def to_yaml(*args)
    {'email' => email}.to_yaml(*args)
  end

  def regenerate_token
    self.email_reset = true
    generate_confirmation_token
  end

  def deliver_email_reset
    Mailer.email_reset(self).deliver
  end

  def generate_api_key
    self.api_key = ActiveSupport::SecureRandom.hex(16)
  end

  def confirm_email!
    self.email_confirmed    = true
    self.confirmation_token = self.email_reset = nil
    save(:validate => false)
  end

  def total_downloads_count
    rubygems.to_a.sum(&:downloads)
  end

  def today_downloads_count
    rubygems.to_a.sum(&:downloads_today)
  end

  def rubygems_downloaded(limit = 10, offset = 0)
    chain = rubygems.by_downloads.offset(offset)
    chain = chain.limit(limit) if limit
    chain
  end
end
