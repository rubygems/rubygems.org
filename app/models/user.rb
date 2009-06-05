class User < ActiveRecord::Base
  include Clearance::User

  has_many :rubygems
  before_create :generate_api_key

  protected

    def generate_api_key
      self.api_key = "#{email}-#{Time.now.to_f}".to_md5
    end
end
