class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  before_create :generate_token

  protected

    def generate_token
      self.token = "#{rand(1000)}#{Time.now.to_f}".to_md5
    end
end
