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

    should "return error tooltip if key if gem ownership is removed" do
      @ownership = create(:ownership)
      @api_key = create(:api_key, push_rubygem: true, user: @ownership.user, ownership: @ownership)
      @ownership.destroy!
      rubygem_name = @ownership.rubygem.name

      expected_dom = <<~HTML.squish.gsub(/>\s+</, "><")
        <span
          class="tooltip__text"
          data-tooltip="Ownership of #{rubygem_name} has been removed after being scoped to this key."\
        >#{rubygem_name} [?]</span>
      HTML

      assert_equal expected_dom, gem_scope(@api_key.reload)
    end
  end
end
