require "test_helper"

class ApiKeyRubygemScopeTest < ActiveSupport::TestCase
  should belong_to :api_key
  should belong_to :ownership
  should validate_presence_of(:ownership)
  should validate_presence_of(:api_key)
  should validate_uniqueness_of(:ownership_id).scoped_to(:api_key_id)

  setup do
    @api_key = create(:api_key)
    @rubygem = create(:rubygem)
    @ownership = create(:ownership, rubygem: @rubygem)
    @api_key_scope = create(:api_key_rubygem_scope, api_key: @api_key, ownership: @ownership)
  end

  should "be valid with factory" do
    assert_predicate build(:api_key_rubygem_scope), :valid?
  end

  context "#soft_delete_api_key!" do
    should "be called if destroyed by association" do
      @ownership.destroy!

      assert_nil @api_key.reload.api_key_rubygem_scope
      assert_predicate @api_key, :soft_deleted?
      assert_predicate @api_key, :soft_deleted_by_ownership?
      assert_equal @rubygem.name, @api_key.reload.soft_deleted_rubygem_name
    end

    should "call #soft_delete_api_key! if not destroyed by association" do
      @api_key.update(ownership: nil)

      assert_nil @api_key.reload.api_key_rubygem_scope
      refute_predicate @api_key, :soft_deleted?
      refute_predicate @api_key, :soft_deleted_by_ownership?
      assert_nil @api_key.reload.soft_deleted_rubygem_name
    end
  end
end
