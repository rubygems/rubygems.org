class User < ActiveRecord::Base
  include Clearance::User
  is_gravtastic

  attr_accessible :handle

  has_many :rubygems, :through    => :ownerships,
                      :order      => "name ASC",
                      :conditions => { 'ownerships.approved' => true }
  has_many :subscribed_gems, :through => :subscriptions,
                             :source  => :rubygem,
                             :order   => "name ASC"
  has_many :ownerships
  has_many :subscriptions
  has_many :web_hooks

  before_validation_on_update :regenerate_token, :if => :email_changed?
  before_create :generate_api_key
  after_update :deliver_email_reset, :if => :email_reset

  validates_uniqueness_of :handle
  validates_format_of :handle, :with => /^[a-z][a-z_\-0-9]*$/, :allow_blank => true
  validates_length_of :handle, :within => (3..15), :allow_blank => true

  def name
    handle || email
  end

  def rubyforge_importer?
    id.to_s == ENV["RUBYFORGE_IMPORTER"]
  end

  def reset_api_key!
    generate_api_key && save!
  end

  def all_hooks
    all     = web_hooks.specific.group_by { |hook| hook.rubygem.name }
    globals = web_hooks.global
    all["all gems"] = globals unless globals.empty?
    all
  end

  def to_json(options = {})
    super(options.merge(:only => :email))
  end

  def to_yaml(*args)
    { 'email' => email }.to_yaml(*args)
  end

  def regenerate_token
    self.email_reset = true
    generate_confirmation_token
  end

  def deliver_email_reset
    Mailer.deliver_email_reset self
  end

  def generate_api_key
    self.api_key = ActiveSupport::SecureRandom.hex(16)
  end
end
