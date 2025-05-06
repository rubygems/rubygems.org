require "test_helper"

class RubygemTransferTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @organization = create(:organization, owners: [@owner])
  
    @rubygem = create(:rubygem, owners: [@owner])
  end

  test "the user performing the gem transfer has the right permission" do
    guest = create(:user)

    transfer = RubygemTransfer.new(created_by: guest, rubygem: @rubygem)

    assert_not transfer.valid?
    assert_includes transfer.errors[:created_by], "does not have permission to transfer this gem"
  end

  test "a completed organization transfer process" do
    transfer = RubygemTransfer.new(created_by: @owner, rubygem: @rubygem, transferable: @organization)
    RubygemTransferOrganization.stub(:transfer!, true) do
      transfer.process!
    end

    assert transfer.completed?
  end


  test "a completde user transfer process" do
    new_owner = create(:user)
    transfer = RubygemTransfer.new(created_by: @owner, rubygem: @rubygem, transferable: new_owner)
    RubygemTransferUser.stub(:transfer!, true) do
      transfer.process!
    end

    assert transfer.completed?
  end

  test "a failed transfer process" do
    transfer = RubygemTransfer.new(created_by: @owner, rubygem: @rubygem, transferable: @organization)
    RubygemTransferOrganization.stub(:transfer!, -> { raise(ActiveRecord::ActiveRecordError, "test") }) do
      assert_raises(ActiveRecord::ActiveRecordError) do
        transfer.process!
      end
    end

    assert transfer.failed?
    assert_not_nil transfer.error
  end
end
