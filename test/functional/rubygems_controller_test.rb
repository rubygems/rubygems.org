require "test_helper"

class RubygemsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "On GET to show for any gem" do
      setup do
        @owners = [@user, create(:user)]
        @rubygem = create(:rubygem, owners: @owners, number: "1.0.0")
        get :show, params: { id: @rubygem.to_param }
      end

      should respond_with :success
      should "renders owner gems overview links" do
        @owners.each do |owner|
          assert page.has_selector?("a[href='#{profile_path(owner.display_id)}']")
        end
      end
    end

    context "On GET to show for any gem without a linkset" do
      setup do
        @owners = [@user, create(:user)]
        @rubygem = create(:rubygem, owners: @owners, number: "1.0.0")
        @rubygem.linkset = nil
        get :show, params: { id: @rubygem.to_param }
      end

      should respond_with :success
      should "render documentation link" do
        assert page.has_selector?("a#docs")
      end
    end

    context "On GET to show for a gem that the user is subscribed to" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        create(:subscription, rubygem: @rubygem, user: @user)
        get :show, params: { id: @rubygem.to_param }
      end

      should respond_with :success
      should "have unsubscribe link" do
        assert page.has_link? "Unsubscribe"
        refute page.has_content? "Subscribe"
      end
    end

    context "On GET to show for a gem that the user is not subscribed to" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        get :show, params: { id: @rubygem.to_param }
      end

      should respond_with :success
      should "have subscribe link" do
        assert page.has_link? "Subscribe"
        refute page.has_content? "Unsubscribe"
      end
    end
  end

  context "On GET to index with no parameters" do
    setup do
      @gems = (1..3).map do |n|
        gem = create(:rubygem, name: "agem#{n}")
        create(:version, rubygem: gem)
        gem
      end
      create(:rubygem, name: "zeta")
      get :index
    end

    should respond_with :success
    should "render links" do
      @gems.each do |g|
        assert page.has_content?(g.name)
        assert page.has_selector?("a[href='#{rubygem_path(g)}']")
      end
    end
  end

  context "On GET to index as an atom feed" do
    setup do
      @versions = (1..2).map { |n| create(:version, created_at: n.hours.ago) }
      # just to make sure one has a different platform and a summary
      @versions << create(:version, created_at: 3.hours.ago, platform: "win32", summary: "&")
      get :index, format: "atom"
    end

    should respond_with :success

    should "render posts with platform-specific titles and links of all subscribed versions" do
      @versions.each do |v|
        assert_select "entry > title", count: 1, text: v.to_title
        assert_select "entry > link[href='#{rubygem_version_url(v.rubygem, v.slug)}']", count: 1
        assert_select "entry > id", count: 1, text: rubygem_version_url(v.rubygem, v.slug)
      end
    end

    should "render valid entry authors" do
      @versions.each do |v|
        assert_select "entry > author > name", text: v.authors
      end
    end

    should "render entry summaries only for versions with summaries" do
      assert_select "entry > summary", count: @versions.count(&:summary?)
      @versions.each do |v|
        assert_select "entry > summary", text: v.summary if v.summary?
      end
    end
  end

  context "On GET to index with a letter" do
    setup do
      @gems = (1..3).map { |n| create(:rubygem, name: "agem#{n}") }
      @zgem = create(:rubygem, name: "zeta")
      create(:version, rubygem: @zgem)
      get :index, params: { letter: "z" }
    end
    should respond_with :success
    should "render links" do
      assert page.has_content?(@zgem.name)
      assert page.has_selector?("a[href='#{rubygem_path(@zgem)}']")
    end
  end

  context "On GET to index with a bad letter" do
    setup do
      @gems = (1..3).map do |n|
        gem = create(:rubygem, name: "agem#{n}")
        create(:version, rubygem: gem)
        gem
      end
      create(:rubygem, name: "zeta")
      get :index, params: { letter: "asdf" }
    end

    should respond_with :success
    should "render links" do
      @gems.each do |g|
        assert page.has_content?(g.name)
        assert page.has_selector?("a[href='#{rubygem_path(g)}']")
      end
    end
  end

  context "On GET to show" do
    setup do
      @latest_version = create(:version, created_at: 1.minute.ago)
      @rubygem = @latest_version.rubygem
      get :show, params: { id: @rubygem.to_param }
    end

    should respond_with :success
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
      assert page.has_content?(@latest_version.number)
      css = "small:contains('#{@latest_version.created_at.to_date.to_formatted_s(:long)}')"
      assert page.has_css?(css)
      assert page.has_content?("Links")
    end
  end

  context "On GET to show with version licenses" do
    setup do
      @latest_version = create(:version)
      @rubygem = @latest_version.rubygem
    end
    should "render plural licenses header for other than one license" do
      @latest_version.update(licenses: nil)
      get :show, params: { id: @rubygem.to_param }
      assert page.has_content?("Licenses")

      @latest_version.update(licenses: %w[MIT GPL-2])
      get :show, params: { id: @rubygem.to_param }
      assert page.has_content?("Licenses")
    end

    should "render singular license header for one line license" do
      @latest_version.update(licenses: ["MIT"])
      get :show, params: { id: @rubygem.to_param }
      assert page.has_content?("License")
      assert page.has_no_content?("Licenses")
    end
  end

  context "On GET to show with a gem that has multiple versions" do
    setup do
      @rubygem = create(:rubygem)
      @versions = [
        create(:version, number: "2.0.0rc1", rubygem: @rubygem, created_at: 1.day.ago),
        create(:version, number: "1.9.9", rubygem: @rubygem, created_at: 1.minute.ago),
        create(:version, number: "1.9.9.rc4", rubygem: @rubygem, created_at: 2.days.ago)
      ]
      get :show, params: { id: @rubygem.to_param }
    end

    should respond_with :success
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
      assert page.has_content?(@versions[0].number)
      css = "small:contains('#{@versions[0].built_at.to_date.to_formatted_s(:long)}')"
      assert page.has_css?(css)

      assert page.has_content?("Versions")
      assert page.has_content?(@versions[2].number)
      css = "small:contains('#{@versions[2].built_at.to_date.to_formatted_s(:long)}')"
      assert page.has_css?(css)
    end

    should "render versions in correct order" do
      assert_select("div.versions > ol > li") do |elements|
        elements.each_with_index do |elem, index|
          assert_select elem, "a", @versions[index].number
        end
      end
    end
  end

  context "On GET to show for a yanked gem with no versions" do
    setup do
      version = create(:version, created_at: 1.minute.ago, indexed: false)
      @rubygem = version.rubygem
    end
    context "when signed out" do
      setup { get :show, params: { id: @rubygem.to_param } }
      should respond_with :success
      should "render info about the gem" do
        assert page.has_content?("This gem is not currently hosted on RubyGems.org")
        assert page.has_no_content?("Versions")
      end
    end
    context "with a signed in user subscribed to the gem" do
      setup do
        @user = create(:user)
        sign_in_as @user
        create(:subscription, user: @user, rubygem: @rubygem)
        get :show, params: { id: @rubygem.to_param }
      end
      should "have unsubscribe link" do
        assert page.has_link? "Unsubscribe"
      end
    end
    context "namespace is reserved" do
      setup do
        @rubygem.update(created_at: 30.days.ago, updated_at: 99.days.ago)
        @owner = create(:user)
        create(:ownership, user: @owner, rubygem: @rubygem)
        get :show, params: { id: @rubygem.to_param }
      end

      should respond_with :success
      should "render info about the gem" do
        assert page.has_content?("The RubyGems.org team has reserved this gem name for 1 more day.")
        assert page.has_no_content?("Versions")
      end
      should "renders owner gems overview link" do
        assert page.has_selector?("a[href='#{profile_path(@owner.display_id)}']")
      end
    end
  end

  context "On GET to show for a gem with no versions" do
    setup do
      @rubygem = create(:rubygem)
      get :show, params: { id: @rubygem.to_param }
    end
    should respond_with :success
    should "render info about the gem" do
      assert page.has_content?("This gem is not currently hosted on RubyGems.org.")
    end
  end

  context "On GET to show for a gem with both runtime and development dependencies" do
    setup do
      @version = create(:version)

      @development = create(:dependency, :development, version: @version)
      @runtime     = create(:dependency, :runtime,     version: @version)

      get :show, params: { id: @version.rubygem.to_param }
    end

    should respond_with :success
    should "show runtime dependencies and development dependencies" do
      assert page.has_content?(@runtime.rubygem.name)
      assert page.has_content?(@development.rubygem.name)
    end
    should "show runtime and development dependencies count" do
      assert page.has_content?(@version.dependencies.runtime.count)
      assert page.has_content?(@version.dependencies.development.count)
    end
  end

  context "On GET to show for a gem with dependencies that are unresolved" do
    setup do
      @version = create(:version)

      @unresolved = create(:dependency, :unresolved, version: @version)

      get :show, params: { id: @version.rubygem.to_param }
    end

    should respond_with :success
    should "show unresolved dependencies" do
      assert page.has_content?(@unresolved.name)
    end
  end

  context "On GET to show for a gem with dependencies that have missing rubygem" do
    setup do
      @version = create(:version)

      @runtime = create(:dependency, :runtime, version: @version)
      @runtime.update_attribute(:requirements, "= 1.0.0")
      @runtime.rubygem.update_column(:name, "foo")

      @missing_dependency = create(:dependency, :runtime, version: @version)
      @missing_dependency.update_attribute(:requirements, "= 1.2.0")
      @missing_dependency.rubygem.update_column(:name, "missing")
      @missing_dependency.update_column(:rubygem_id, nil)

      get :show, params: { id: @version.rubygem.to_param }
    end

    should respond_with :success
    should "show only dependencies that have rubygem" do
      assert page.has_content?(@runtime.rubygem.name)
      assert page.has_no_content?("1.2.0")
    end
  end

  context "On GET to show for a gem with runtime dependencies that have a bad link" do
    setup do
      @version = create(:version)
      @runtime = create(:dependency, :runtime, version: @version)
      @runtime.rubygem.update_column(:name, "foo>0.1.1")
      get :show, params: { id: @version.rubygem.to_param }
    end

    should respond_with :success
    should "show runtime dependencies and development dependencies" do
      assert page.has_content?(@runtime.rubygem.name)
    end
  end

  context "On GET to show for nonexistent gem" do
    setup do
      get :show, params: { id: "blahblah" }
    end

    should respond_with :not_found
  end

  context "On GET to show for a reserved gem" do
    setup do
      get :show, params: { id: Patterns::GEM_NAME_RESERVED_LIST.sample }
    end

    should respond_with :success
    should "render reserved page" do
      assert page.has_content? "This namespace is reserved by rubygems.org."
    end
  end

  context "When not logged in" do
    context "On GET to show for a gem" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        get :show, params: { id: @rubygem.to_param }
      end

      should respond_with :success
      should "have an subscribe link that goes to the sign in page" do
        assert page.has_selector?("a[href='#{sign_in_path}']")
      end
      should "not have an unsubscribe link" do
        refute page.has_selector?("a#unsubscribe")
      end
    end
  end
end
