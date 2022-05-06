require "test_helper"

class ApiKeysHelperTest < ActionView::TestCase
  context "gem_scope" do
    should "return gem name" do
      @ownership = create(:ownership)
      @api_key = create(:api_key, push_rubygem: true, user: @ownership.user, ownership: @ownership)

      assert_equal @ownership.rubygem.name, gem_scope(@api_key)
    end

    should "return all gems if there is no scope specified" do
      assert_equal "All Gems", gem_scope(create(:api_key))
    end

    should "return if key if gem ownership is removed" do
      @ownership = create(:ownership)
      @api_key = create(:api_key, push_rubygem: true, user: @ownership.user, ownership: @ownership)
      @ownership.destroy!

      assert_nil gem_scope(@api_key.reload)
    end
  end
end
