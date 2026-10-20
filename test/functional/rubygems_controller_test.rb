# frozen_string_literal: true

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
        get :show, params: { id: @rubygem.slug }
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
        get :show, params: { id: @rubygem.slug }
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
        get :show, params: { id: @rubygem.slug }
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
        get :show, params: { id: @rubygem.slug }
      end

      should respond_with :success
      should "have subscribe link" do
        assert page.has_link? "Subscribe"
        refute page.has_content? "Unsubscribe"
      end
    end

    context "On GET to security_events for a gem that the user is not an owner of" do
      setup { get :security_events, params: { id: create(:rubygem).slug } }

      should respond_with :forbidden
    end

    context "On GET to security_events for a gem that the user is an owner of" do
      setup do
        @rubygem = create(:rubygem)
        @other_user = create(:user)
        Current.set(user: @user) do
          @rubygem.ownerships.create!(user: @other_user, authorizer: @user).destroy!
        end
        @rubygem.ownerships.create!(user: @user, authorizer: @user).confirm!
        get :security_events, params: { id: @rubygem.slug }
      end

      should respond_with :success

      should "include the security events" do
        assert_text "Owner Added"
        assert_text "Owner Confirmed"
        assert_text "Owner Removed"
      end
    end
  end

  context "On GET to index with no parameters" do
    should "render the original alphabetical A listing" do
      create(:rubygem, name: "amethyst", number: "1.0.0")
      create(:rubygem, name: "amber", number: "1.0.0")
      create(:rubygem, name: "aardvark")
      create(:rubygem, name: "zebra", number: "1.0.0")

      get :index

      assert_response :success
      assert_equal %w[amber amethyst], page.all("[data-testid='rubygem-name']").map(&:text)
      assert page.has_selector?("nav[aria-label='Breadcrumb'] [aria-current='page']", text: "Gems", exact_text: true)
      assert page.has_link?("B", href: rubygems_path(letter: "B"))
      refute page.has_selector?("#just-released")
    end
  end

  context "On GET to explore" do
    setup do
      Rails.cache.delete(RubygemsController::MOST_DEPENDED_ON_CACHE_KEY)

      @old_release = create(:rubygem, name: "old-release", created_at: 30.days.ago)
      create(:version, rubygem: @old_release, created_at: 20.days.ago)

      @brand_new = create(:rubygem, name: "brand-new", created_at: 2.days.ago)
      create(:version, rubygem: @brand_new, number: "1.0.0.pre", created_at: 2.days.ago)

      @new_with_update = create(:rubygem, name: "new-with-update", created_at: 3.days.ago)
      create(:version, rubygem: @new_with_update, number: "0.1.0", created_at: 3.days.ago)
      create(:version, rubygem: @new_with_update, number: "0.2.0", created_at: 1.day.ago)

      @new_last_month = create(:rubygem, name: "new-last-month", created_at: 30.days.ago)
      create(:version, rubygem: @new_last_month, created_at: 30.days.ago)

      @attested = create(:rubygem, name: "attested")
      create(:attestation, version: create(:version, rubygem: @attested, created_at: 1.hour.ago))

      @depended_on = create(:rubygem, name: "depended-on", number: "1.0.0")
      create_list(:dependency, 2, :runtime, rubygem: @depended_on)

      get :explore
    end

    should respond_with :success

    should "list recent releases under Just released, linking to the full list" do
      section = page.find_by_id("just-released")

      assert section.has_link?(@attested.name, href: rubygem_path(@attested.slug))
      refute section.has_content?(@old_release.name)
      assert section.has_link?(href: news_path)
    end

    should "list gems first published this week with a single version under New gems" do
      section = page.find_by_id("new-gems")

      assert section.has_link?(@brand_new.name, href: rubygem_path(@brand_new.slug))
      refute section.has_content?(@new_with_update.name)
      refute section.has_content?(@new_last_month.name)
      refute section.has_link?(href: news_path)
    end

    should "link Popular to the full popular list" do
      assert page.find_by_id("popular").has_link?(href: popular_news_path)
    end

    should "rank gems by runtime dependents and show the count instead of downloads" do
      section = page.find_by_id("most-depended-on")

      assert section.has_link?(@depended_on.name, href: rubygem_path(@depended_on.slug))
      assert section.has_content?("2 dependents")
      refute section.has_selector?("[title^='#{I18n.t('total_downloads')}']")
    end

    should "list releases with provenance" do
      section = page.find_by_id("provenance")

      assert section.has_link?(@attested.name, href: rubygem_path(@attested.slug))
      refute section.has_content?(@brand_new.name)
    end

    should "link to the A listing instead of an A-Z list" do
      assert page.has_link?(I18n.t("rubygems.explore.browse_by_letter"), href: rubygems_path(letter: "A"))
      refute page.has_selector?("a[href='#{rubygems_path(letter: 'B')}']")
    end

    should "show Explore as the current breadcrumb" do
      assert page.has_selector?("nav[aria-label='Breadcrumb'] [aria-current='page']", text: "Explore", exact_text: true)
    end
  end

  context "On GET to explore with more recent gems than fit in a section" do
    should "select the five most downloaded versions rather than gem totals or the five newest releases" do
      %w[first second third fourth fifth sixth].each_with_index do |name, index|
        gem = create(:rubygem, name:, downloads: (6 - index) * 1_000, created_at: (index + 1).days.ago)
        version = create(:version, rubygem: gem, created_at: (index + 1).days.ago)
        version.gem_download.update!(count: (index + 1) * 100)
      end

      get :explore

      expected_downloads = %w[600 500 400 300 200]
      expected_links = %w[sixth fifth fourth third second].map { |name| rubygem_path(name) }
      %w[just-released new-gems].each do |id|
        links = page.all("##{id} a[href^='/gems/']").map { |link| link[:href] }

        assert_equal expected_links, links
        assert_equal expected_downloads, page.all("##{id} span[title^='Downloads for']").map(&:text)
      end
    end

    should "rank and display one consistent version per gem rather than an older or alternate platform's downloads" do
      gem = create(:rubygem, name: "multi-platform", created_at: 30.days.ago)
      old = create(:version, rubygem: gem, number: "1.0.0", created_at: 20.days.ago)
      old.gem_download.update!(count: 90_000)
      ruby = create(:version, rubygem: gem, number: "2.0.0", created_at: 2.days.ago)
      ruby.gem_download.update!(count: 120)
      java = create(:version, rubygem: gem, number: "2.0.0", platform: "java", created_at: 1.day.ago)
      java.gem_download.update!(count: 8_000)
      other = create(:rubygem, name: "platform-only")
      other_version = create(:version, rubygem: other, number: "3.0.0", platform: "java")
      other_version.gem_download.update!(count: 250)

      get :explore

      assert_equal([rubygem_path(other.name), rubygem_path(gem.name)], page.all("#just-released a[href^='/gems/']").pluck(:href))
      assert_equal %w[250 120], page.all("#just-released span[title^='Downloads for']").map(&:text)
      assert_equal %w[3.0.0 2.0.0], page.all("#just-released code").map(&:text)
    end
  end

  context "On GET to explore with mixed-platform provenance" do
    should "require provenance on the displayed preferred release and order qualifying releases newest first" do
      mismatched = create(:rubygem, name: "unattested-ruby")
      create(:attestation, version: create(:version, rubygem: mismatched, number: "1.0.0", platform: "java", created_at: 3.days.ago))
      create(:version, rubygem: mismatched, number: "2.0.0", created_at: 2.days.ago)

      preferred = create(:rubygem, name: "attested-ruby")
      create(:attestation, version: create(:version, rubygem: preferred, number: "1.0.0", created_at: 3.days.ago))
      create(:version, rubygem: preferred, number: "2.0.0", platform: "java", created_at: 2.days.ago)

      platform_only = create(:rubygem, name: "attested-java")
      java_release = create(:version, rubygem: platform_only, number: "3.0.0", platform: "java", created_at: 1.day.ago)
      java_release.gem_download.update!(count: 321)
      create_list(:attestation, 2, version: java_release)

      superseded = create(:rubygem, name: "superseded-attestation")
      create(:attestation, version: create(:version, rubygem: superseded, number: "1.0.0", created_at: 3.days.ago))
      create(:version, rubygem: superseded, number: "2.0.0", created_at: 2.days.ago)

      old = create(:rubygem, name: "old-attestation")
      create(:attestation, version: create(:version, rubygem: old, created_at: (Gemcutter::NEWS_DAYS_LIMIT + 1.day).ago))
      create_list(:version, 5)

      get :explore

      assert_response :success
      assert_equal [rubygem_path(platform_only.name), rubygem_path(preferred.name)], page.all("#provenance a[href^='/gems/']").pluck(:href)
      assert_equal %w[3.0.0 1.0.0], page.all("#provenance code").map(&:text)
      assert page.find_by_id("provenance").has_selector?("span[title='Downloads for attested-java-3.0.0-java: 321']")
    end
  end

  context "On GET to explore with no recent gems" do
    setup do
      Rails.cache.delete(RubygemsController::MOST_DEPENDED_ON_CACHE_KEY)
      get :explore
    end

    should respond_with :success
    should "show an empty state in each section" do
      %w[just-released new-gems popular most-depended-on provenance].each do |id|
        assert page.find("##{id}").has_content?("Nothing here yet.")
      end
    end
  end

  context "On repeated GETs to explore" do
    setup do
      # Other workers' setups flush the shared memcached (Rack::Attack.cache.store.clear),
      # so give this test a private store.
      Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
      @rubygem = create(:rubygem, name: "cached-dependency", number: "1.0.0")
    end

    should "compute the most depended on counts once and serve them from the cache" do
      Rubygem.expects(:most_depended_on_counts).once.returns({ @rubygem.id => 42 })

      2.times do
        get :explore

        assert page.find_by_id("most-depended-on").has_content?("42 dependents")
      end
    end
  end

  context "On GET to index with only a page" do
    setup do
      @gem = create(:rubygem, name: "apage", number: "1.0.0")
      get :index, params: { page: 1 }
    end

    should respond_with :success
    should "render the A listing rather than the explore hub" do
      assert page.has_link?(@gem.name, href: rubygem_path(@gem.slug))
      refute page.has_selector?("#just-released")
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
        assert_select "entry > link[href='#{rubygem_version_url(v.rubygem.slug, v.slug)}']", count: 1
        assert_select "entry > id", count: 1, text: rubygem_version_url(v.rubygem.slug, v.slug)
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
      assert page.has_selector?("a[href='#{rubygem_path(@zgem.slug)}']")
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
        assert page.has_selector?("a[href='#{rubygem_path(g.slug)}']")
      end
    end
  end

  context "On GET to show" do
    setup do
      @latest_version = create(:version, created_at: 1.minute.ago)
      @rubygem = @latest_version.rubygem
      get :show, params: { id: @rubygem.slug }
    end

    should respond_with :success
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
      assert page.has_content?(@latest_version.number)
      assert page.has_css?("[data-testid='version-date']", text: @latest_version.authored_at.to_date.to_fs(:long))
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
      get :show, params: { id: @rubygem.slug }

      assert page.has_content?("Licenses")

      @latest_version.update(licenses: %w[MIT GPL-2])
      get :show, params: { id: @rubygem.slug }

      assert page.has_content?("Licenses")
    end

    should "render singular license header for one line license" do
      @latest_version.update(licenses: ["MIT"])
      get :show, params: { id: @rubygem.slug }

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
      get :show, params: { id: @rubygem.slug }
    end

    should respond_with :success
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
      assert page.has_content?(@versions[0].number)
      assert page.has_css?("[data-testid='version-date']", text: @versions[0].built_at.to_date.to_fs(:long))

      assert page.has_content?("Versions")
      assert page.has_content?(@versions[2].number)

      assert page.has_css?("[data-testid='version-date']", text: @versions[2].built_at.to_date.to_fs(:long))
    end

    should "render versions in correct order" do
      page_versions = css_select("[data-testid='gem-versions'] > li > div > span").map(&:text)

      assert_equal @versions.map(&:number), page_versions
    end
  end

  context "On GET to show for a yanked gem with no versions" do
    setup do
      version = create(:version, :yanked, created_at: 1.minute.ago)
      @rubygem = version.rubygem
    end
    context "when signed out" do
      setup { get :show, params: { id: @rubygem.slug } }
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
        get :show, params: { id: @rubygem.slug }
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
        get :show, params: { id: @rubygem.slug }
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
      get :show, params: { id: @rubygem.slug }
    end
    should respond_with :success

    should "render info about the gem" do
      assert page.has_content?("This gem is not currently hosted on RubyGems.org.")
    end
  end

  context "On GET to show for a gem with dependencies" do
    setup do
      @version = create(:version)
      @runtime = create(:dependency, :runtime, version: @version)

      get :show, params: { id: @version.rubygem.slug }
    end

    should respond_with :success

    should "link the dependencies tab to the dependencies page" do
      assert page.has_link?("Dependencies", href: rubygem_version_dependencies_path(@version.rubygem.slug, @version.slug))
    end
  end

  context "On GET to show for a gem without dependencies" do
    setup do
      @version = create(:version)

      get :show, params: { id: @version.rubygem.slug }
    end

    should respond_with :success
    should "show a disabled dependencies tab" do
      refute page.has_link?("Dependencies")
      assert page.has_selector?("span[aria-disabled='true']", text: "Dependencies")
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
      reservation = create(:gem_name_reservation)
      get :show, params: { id: reservation.name }
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
        get :show, params: { id: @rubygem.slug }
      end

      should respond_with :success

      should "have an subscribe link that goes to the sign in page" do
        assert page.has_selector?("a[href='#{sign_in_path}']")
      end
      should "not have an unsubscribe link" do
        refute page.has_selector?("a#unsubscribe")
      end
    end

    context "On GET to security_events for a gem" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        get :security_events, params: { id: @rubygem.slug }
      end

      should respond_with :redirect
    end
  end

  context "when gem is owned by an organization" do
    setup do
      @owner = create(:user)
      @rubygem = create(:rubygem)
      @version = create(:version, rubygem: @rubygem)
      @organization = create(:organization, name: "Test Org", handle: "test-org", rubygems: [@rubygem], owners: [@owner])
    end

    should "link the organization profile page" do
      get :show, params: { id: @rubygem.slug }

      assert page.has_link?(@organization.name, href: organization_path(@organization))
    end
  end

  context "when a gem is owned by an organization and has outside contributors" do
    setup do
      @owner = create(:user)
      @rubygem = create(:rubygem, owners: [@owner])
      @version = create(:version, rubygem: @rubygem)
      @organization = create(:organization, owners: [@owner])
      @outside_contributor = create(:user)
      create(:ownership, rubygem: @rubygem, user: @outside_contributor, role: :maintainer)
    end

    should "display outside contributors" do
      get :show, params: { id: @rubygem.slug }

      assert page.has_selector?("a[href='#{profile_path(@outside_contributor.display_id)}']")
    end
  end

  context "On GET to show for a gem with content-addressable versions" do
    setup do
      @rubygem = create(:rubygem, name: "content-addressable-ui-test")
      @newest = create_content_addressable_version(number: "0.2.0", platform: "arm64-darwin", ruby_abi: "4.0")
      @source = create(:version, rubygem: @rubygem, number: "0.1.0")
      @fat = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "arm64-darwin", gem_platform: "arm64-darwin")
      @arm64 = create_content_addressable_version(number: "0.1.0", platform: "arm64-darwin", ruby_abi: "4.0")
      @x86 = create_content_addressable_version(number: "0.1.0", platform: "x86_64-linux", ruby_abi: "3.3")
    end

    should "render grouped versions with content addresses and build type badges" do
      get :show, params: { id: @rubygem.slug }

      assert_response :success
      assert_equal %w[0.2.0 0.1.0], version_group_text
      assert_select "[data-testid='gem-versions'] p", text: "arm64-darwin"
      assert_select "[data-testid='gem-versions'] p", text: "x86_64-linux"
      [@newest, @arm64, @x86].each do |version|
        assert_select "[data-testid='gem-versions'] a[href=?]",
                      rubygem_version_path(@rubygem.slug, version.slug), text: /Ruby ABI #{version.ruby_abi}/
        assert_select "[data-testid='gem-versions']", text: /content address: #{version.content_address}/
      end
      assert_select "[data-testid='gem-versions'] a[href=?]", rubygem_version_path(@rubygem.slug, @source.slug), text: /source/
      assert_select "[data-testid='gem-versions'] a[href=?]", rubygem_version_path(@rubygem.slug, @fat.slug), text: /multi-abi/
      assert_select "[data-testid='gem-versions']", text: /Ruby ABI 4.0/
      assert_select "[data-testid='gem-versions']", text: /single-abi/, count: 0
    end
  end

  context "On GET to show with advisories" do
    setup do
      @rubygem = create(:rubygem, name: "actionpack")
      create(:version, rubygem: @rubygem, number: "1.0.0")
      create(:version, rubygem: @rubygem, number: "2.0.0")
      create(:advisory, :with_rubygem, rubygem: @rubygem,
             ranges: ["introduced" => "1.0.0", "fixed" => "2.0.0"],
             summary: "XSS in Action Pack",
             identifier: "GHSA-test-show-0001")
    end

    should "show advisories affecting the latest version to logged-out visitors" do
      create(:advisory, :with_rubygem, :unfixed, rubygem: @rubygem,
             summary: "RCE in Action Pack",
             identifier: "GHSA-test-show-0002",
             severity: :high)

      get :show, params: { id: @rubygem.slug }

      assert page.has_css?("[data-testid='gem-advisories']")
      assert page.has_content?("RCE in Action Pack")
      assert page.has_link?("View advisory")
      assert page.has_content?("vulnerable")
    end

    should "not show a patched latest version as vulnerable for older ranges" do
      get :show, params: { id: @rubygem.slug }

      refute page.has_css?("[data-testid='gem-advisories']")
      assert page.has_content?("vulnerable")
    end

    should "show advisories to signed-in users" do
      create(:advisory, :with_rubygem, :unfixed, rubygem: @rubygem,
             summary: "RCE in Action Pack",
             identifier: "GHSA-test-show-0004")
      sign_in_as(create(:user))
      get :show, params: { id: @rubygem.slug }

      assert page.has_content?("RCE in Action Pack")
    end

    should "hide withdrawn advisories" do
      create(:advisory, :with_rubygem, :withdrawn, :unfixed, rubygem: @rubygem,
             summary: "Withdrawn advisory",
             identifier: "GHSA-test-show-0003")

      get :show, params: { id: @rubygem.slug }

      refute page.has_content?("Withdrawn advisory")
    end
  end

  private

  def create_content_addressable_version(number:, platform:, ruby_abi:)
    create(:version,
           rubygem: @rubygem,
           number: number,
           platform: platform,
           gem_platform: platform,
           ruby_abi: ruby_abi,
           required_ruby_version: "~> #{ruby_abi}.0",
           required_rubygems_version: Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION,
           sha256: Digest::SHA2.base64digest([@rubygem.name, number, platform, ruby_abi].join("-")))
  end

  def version_group_text
    css_select("[data-testid='gem-versions'] > li > div > span").map(&:text)
  end
end
