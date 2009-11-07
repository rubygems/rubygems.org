class User < ActiveRecord::Base
  include Clearance::User

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

  protected

    def generate_api_key
      self.api_key = "#{email}-#{Time.now.to_f}".to_md5
    end
end
