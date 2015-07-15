require 'test_helper'

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
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should render_template :show
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
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should "render documentation link" do
        assert page.has_selector?("a#docs")
      end
    end

    context "On GET to show for another user's gem" do
      setup do
        @rubygem = create(:rubygem)
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should render_template :show
      should "not render edit link" do
        assert ! page.has_selector?("a[href='#{edit_rubygem_path(@rubygem)}']")
      end
    end

    context "On GET to show for this user's gem" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should render_template :show
      should "render edit link" do
        assert page.has_selector?("a[href='#{edit_rubygem_path(@rubygem)}']")
      end
    end

    context "On GET to show for a gem that the user is subscribed to" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        create(:subscription, rubygem: @rubygem, user: @user)
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should "have a visible unsubscribe link" do
        assert page.has_selector?("a[style='display:inline-block']", text: 'Unsubscribe')
      end
    end

    context "On GET to show for a gem that the user is not subscribed to" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should "have a visible subscribe link" do
        assert page.has_selector?("a[style='display:inline-block']", text: 'Subscribe')
      end
    end

    context "On GET to edit for this user's gem" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
        get :edit, id: @rubygem.to_param
      end

      should respond_with :success
      should render_template :edit
      should "render form" do
        assert page.has_selector?("form")
        assert page.has_selector?("input#linkset_code")
        assert page.has_selector?("input#linkset_docs")
        assert page.has_selector?("input#linkset_wiki")
        assert page.has_selector?("input#linkset_mail")
        assert page.has_selector?("input#linkset_bugs")
        assert page.has_selector?("input[type='submit']")
      end
    end

    context "On GET to edit for another user's gem" do
      setup do
        @other_user = create(:user)
        @rubygem = create(:rubygem, owners: [@other_user], number: "1.0.0")
        get :edit, id: @rubygem.to_param
      end
      should respond_with :redirect
      should redirect_to('the homepage') { root_url }
      should set_flash.to("You do not have permission to edit this gem.")
    end

    context "On PUT to update for this user's gem that is successful" do
      setup do
        @url = "http://github.com/qrush/gemcutter"
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
        put :update, id: @rubygem.to_param, linkset: {code: @url, docs: 'http://docs.com', wiki: 'http://wiki.com', mail: 'http://mail.com', bugs: 'http://bugs.com'}
      end
      should respond_with :redirect
      should redirect_to('the gem') { rubygem_path(@rubygem) }
      should set_flash.to("Gem links updated.")
      should "update source code url" do
        assert_equal @url, Rubygem.last.linkset.code
      end
      should "update documentation rul" do
        assert_equal 'http://docs.com', Rubygem.last.linkset.docs
      end
      should "update wiki url" do
        assert_equal 'http://wiki.com', Rubygem.last.linkset.wiki
      end
      should "update mailing list url" do
        assert_equal 'http://mail.com', Rubygem.last.linkset.mail
      end
      should "update bugtracker url" do
        assert_equal 'http://bugs.com', Rubygem.last.linkset.bugs
      end
    end

    context "On PUT to update for this user's gem that fails" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
        @url = "totally not a url"
        put :update, id: @rubygem.to_param, linkset: {code: @url}
      end
      should respond_with :success
      should render_template :edit
      should "not update linkset" do
        assert_not_equal @url, Rubygem.last.linkset.code
      end
      should "render error messages" do
        assert page.has_content?("error prohibited")
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
    should render_template :index
    should "render links" do
      @gems.each do |g|
        assert page.has_content?(g.name)
        assert page.has_selector?("a[href='#{rubygem_path(g)}']")
      end
    end
    should "display 'gems' in pagination summary" do
      assert page.has_content?("all #{@gems.count} gems")
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
      assert_select "entry > summary", count: @versions.select {|v| v.summary? }.size
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
      get :index, letter: "z"
    end
    should respond_with :success
    should render_template :index
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
      get :index, letter: "asdf"
    end

    should respond_with :success
    should render_template :index
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
      get :show, id: @rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
      assert page.has_content?(@latest_version.number)
      assert page.has_css?("small:contains('#{@latest_version.built_at.to_date.to_formatted_s(:long)}')")
      assert page.has_content?("Links")
    end
  end

  context "On GET to show with version licenses" do
    setup do
      @latest_version = create(:version)
      @rubygem = @latest_version.rubygem
    end
    should "render plural licenses header for other than one license" do
      @latest_version.update_attributes(licenses: nil)
      get :show, id: @rubygem.to_param
      assert page.has_content?("Licenses")

      @latest_version.update_attributes(licenses: ["MIT", "GPL-2"])
      get :show, id: @rubygem.to_param
      assert page.has_content?("Licenses")
    end

    should "render singular license header for one line license" do
      @latest_version.update_attributes(licenses: ["MIT"])
      get :show, id: @rubygem.to_param
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
      get :show, id: @rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
      assert page.has_content?(@versions[0].number)
      assert page.has_css?("small:contains('#{@versions[0].built_at.to_date.to_formatted_s(:long)}')")

      assert page.has_content?("Versions")
      assert page.has_content?(@versions[2].number)
      assert page.has_css?("small:contains('#{@versions[2].built_at.to_date.to_formatted_s(:long)}')")
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
    context 'when signed out' do
      setup { get :show, id: @rubygem.to_param }
      should respond_with :success
      should render_template :show
      should "render info about the gem" do
        assert page.has_content?("This gem has been yanked")
        assert page.has_no_content?('Versions')
      end
    end
    context 'with a signed in user subscribed to the gem' do
      setup do
        @user = create(:user)
        sign_in_as @user
        create(:subscription, user: @user, rubygem: @rubygem)
        get :show, id: @rubygem.to_param
      end
      should "have a visible unsubscribe link" do
        assert page.has_selector?("a[style='display:inline-block']", text: 'Unsubscribe')
      end
    end
  end

  context "On GET to show for a gem with no versions" do
    setup do
      @rubygem = create(:rubygem)
      get :show, id: @rubygem.to_param
    end
    should respond_with :success
    should render_template :show
    should "render info about the gem" do
      assert page.has_content?("This gem is not currently hosted on Gemcutter.")
    end
  end

  context "On GET to show for a gem with both runtime and development dependencies" do
    setup do
      @version = create(:version)

      @development = create(:development_dependency, version: @version)
      @runtime     = create(:runtime_dependency,     version: @version)

      get :show, id: @version.rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should "show runtime dependencies and development dependencies" do
      assert page.has_content?(@runtime.rubygem.name)
      assert page.has_content?(@development.rubygem.name)
    end
  end

  context "On GET to show for a gem with dependencies that are unresolved" do
    setup do
      @version = create(:version)

      @unresolved = create(:unresolved_dependency, version: @version)

      get :show, id: @version.rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should "show unresolved dependencies" do
      assert page.has_content?(@unresolved.name)
    end
  end

  context "On GET to show for a gem with runtime dependencies that have a bad link" do
    setup do
      @version = create(:version)
      @runtime = create(:runtime_dependency, version: @version)
      @runtime.rubygem.update_column(:name, 'foo>0.1.1')
      get :show, id: @version.rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should "show runtime dependencies and development dependencies" do
      assert page.has_content?(@runtime.rubygem.name)
    end
  end

  context "On GET to show for nonexistent gem" do
    setup do
      get :show, id: "blahblah"
    end

    should respond_with :not_found
  end

  context "When not logged in" do
    context "On GET to show for a gem" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        get :show, id: @rubygem.to_param
      end

      should respond_with :success
      should "have an subscribe link that goes to the sign in page" do
        assert page.has_selector?("a[href='#{sign_in_path}']")
      end
      should "not have an unsubscribe link" do
        assert ! page.has_selector?("a#unsubscribe")
      end
    end

    context "On GET to edit" do
      setup do
        @rubygem = create(:rubygem)
        get :edit, id: @rubygem.to_param
      end
      should respond_with :redirect
      should redirect_to('the homepage') { root_url }
    end

    context "On PUT to update" do
      setup do
        @rubygem = create(:rubygem)
        put :update, id: @rubygem.to_param, linkset: {}
      end
      should respond_with :redirect
      should redirect_to('the homepage') { root_url }
    end
  end
end
