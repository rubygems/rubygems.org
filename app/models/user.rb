class User < ActiveRecord::Base
  include Clearance::User
  is_gravtastic

  has_many :rubygems, :through    => :ownerships,
                      :order      => "name ASC",
                      :conditions => { 'ownerships.approved' => true }
  has_many :subscribed_gems, :through => :subscriptions,
                             :source  => :rubygem,
                             :order   => "name ASC"
  has_many :ownerships
  has_many :subscriptions
  before_create :generate_api_key

  def rubyforge_importer?
    id.to_s == ENV["RUBYFORGE_IMPORTER"]
  end

  def reset_api_key!
    generate_api_key && save!
  end

  def to_json(options = {})
    super(options.merge(:only => :email))
  end

  def to_yaml(*args)
    { 'email' => email }.to_yaml(*args)
  end

  protected

    def generate_api_key
      self.api_key = ActiveSupport::SecureRandom.hex(16)
    end
end
