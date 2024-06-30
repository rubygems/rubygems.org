require "test_helper"

class OrgTest < ActiveSupport::TestCase
  should have_many(:memberships).dependent(:destroy)
  should have_many(:unconfirmed_memberships).dependent(:destroy)
  should have_many(:users).through(:memberships)
end
