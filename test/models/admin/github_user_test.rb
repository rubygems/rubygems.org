require "test_helper"

class Admin::GitHubUserTest < ActiveSupport::TestCase
  should validate_presence_of :login
  should validate_presence_of :github_id
  should validate_uniqueness_of :github_id
  should validate_presence_of :info_data
end
