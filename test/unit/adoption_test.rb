require 'test_helper'

class AdoptionTest < ActiveSupport::TestCase
  subject { create(:adoption) }

  should belong_to :user
  should belong_to :rubygem
  should validate_presence_of(:rubygem)
  should validate_presence_of(:user)
  should validate_presence_of(:note)
  should validate_uniqueness_of(:user_id).scoped_to(:rubygem_id)
end
