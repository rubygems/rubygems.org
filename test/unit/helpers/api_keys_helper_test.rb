require "test_helper"

class ApiKeysHelperTest < ActionView::TestCase
  context "gem_scope" do
    should "return gem name" do
      @ownership = create(:ownership)
      @api_key = create(:api_key, scopes: %i[push_rubygem], owner: @ownership.user, ownership: @ownership)

      assert_equal @ownership.rubygem.name, gem_scope(@api_key)
    end

    should "return all gems if there is no scope specified" do
      assert_equal "All Gems", gem_scope(create(:api_key))
    end

    should "return error tooltip if key if gem ownership is removed" do
      @ownership = create(:ownership)
      @api_key = create(:api_key, scopes: %i[push_rubygem], owner: @ownership.user, ownership: @ownership)
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

  def expected_checkbox(scope, exclusive: false, gem_scope: false)
    data = { exclusive_checkbox_target: exclusive ? "exclusive" : "inclusive" }
    data[:gem_scope_target] = "checkbox" if gem_scope

    [
      scope,
      { class: "form__checkbox__input", id: scope, data: },
      "true",
      "false"
    ]
  end

  context "api_key_checkbox" do
    setup do
      @f = Object.new
      def @f.check_box(*args)
        args
      end
    end

    should "return checkbox for exclusive scope" do
      scope = ApiKey::EXCLUSIVE_SCOPES.first

      assert_equal expected_checkbox(scope, exclusive: true), api_key_checkbox(@f, scope)
    end

    should "return checkbox for gem scope" do
      scopes = ApiKey::APPLICABLE_GEM_API_SCOPES

      scopes.each do |scope|
        assert_equal expected_checkbox(scope, gem_scope: true), api_key_checkbox(@f, scope)
      end
    end

    should "return checkbox for normal scope" do
      scopes = ApiKey::API_SCOPES - ApiKey::EXCLUSIVE_SCOPES - ApiKey::APPLICABLE_GEM_API_SCOPES

      scopes.each do |scope|
        assert_equal expected_checkbox(scope), api_key_checkbox(@f, scope)
      end
    end
  end
end
