require 'test_helper'

class OwnershipTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert build(:ownership).valid?
  end

  should belong_to :rubygem
  should have_db_index :rubygem_id
  should belong_to :user
  should have_db_index :user_id

  context "with ownership" do
    setup do
      @ownership = create(:ownership)
      create(:version, rubygem: @ownership.rubygem)
    end

    subject { @ownership }

    should validate_uniqueness_of(:user_id).scoped_to(:rubygem_id)
  end
end
