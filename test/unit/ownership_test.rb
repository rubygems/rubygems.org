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

  context "with multiple ownerships on the same rubygem" do
    setup do
      @rubygem       = create(:rubygem)
      @ownership_one = create(:ownership, rubygem: @rubygem)
      @ownership_two = create(:ownership, rubygem: @rubygem)
    end

    should "allow deletion of one ownership" do
      @ownership_one.destroy
      assert_equal 1, @rubygem.owners.length
    end

    should "not allow deletion of both ownerships" do
      @ownership_one.destroy
      @ownership_two.destroy
      assert_equal 1, @rubygem.owners.length
      assert_equal "Can't delete last owner of a gem.", @ownership_two.errors[:base].first
    end
  end
end
