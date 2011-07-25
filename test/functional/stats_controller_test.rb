require 'test_helper'

class StatsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @number_of_gems      = 1337
      @number_of_users     = 101
      @number_of_downloads = 42
      @most_downloaded     = [Factory(:rubygem)]

      stub(Rubygem).total_count { @number_of_gems }
      stub(Download).count { @number_of_downloads }
      stub(Rubygem).downloaded { @most_downloaded }
      stub(User).count { @number_of_users }

      get :index
    end

    should respond_with :success
    should render_template :index
    should assign_to(:number_of_gems) { @number_of_gems }
    should assign_to(:number_of_users) { @number_of_users }
    should assign_to(:number_of_downloads) { @number_of_downloads }
    should assign_to(:most_downloaded) { @most_downloaded }

    should "display number of gems" do
      assert page.has_content?("1,337")
    end

    should "display number of users" do
      assert page.has_content?("101")
    end

    should "display number of downloads" do
      assert page.has_content?("42")
    end

    should "load up the number of gems, users, and downloads" do
      assert_received(User)     { |subject| subject.count }
      assert_received(Rubygem)  { |subject| subject.total_count }
      assert_received(Download) { |subject| subject.count }
      assert_received(Rubygem)  { |subject| subject.downloaded.with(10) }
    end
  end

  context "On GET to stats" do
    setup do
      @version = Factory(:version)
      @rubygem = @version.rubygem
      @versions = @versions = @rubygem.versions.limit(5)
      get :show, :rubygem_id => @rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should assign_to(:rubygem) { @rubygem }
    should assign_to(:version) { @version }
    should assign_to(:versions) { @versions }
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
    end
    should "display a dropdown to choose the version to show" do
      assert ! page.has_selector?('select#version_for_stats')
    end
    should "see that stats are an overview" do
      assert page.has_content?("stats overview")
    end
  end

  context "On GET to stats with a gem that has multiple versions" do
    setup do
      @rubygem = Factory(:rubygem)
      @older_version = Factory(:version, :number => "1.0.0", :rubygem => @rubygem)
      @latest_version = Factory(:version, :number => "2.0.0", :rubygem => @rubygem)
      get :show, :rubygem_id => @rubygem.to_param
    end

    should respond_with :success
    should render_template :show
    should assign_to(:rubygem) { @rubygem }
    should assign_to(:version) { @latest_version }
    should assign_to(:versions) { [@latest_version, @older_version] }
    should "display a dropdown to choose the version to show" do
      assert page.has_selector?('select#version_for_stats')
    end
  end

  context "On GET to stats" do
    setup do
      @version        = Factory(:version)
      rubygem         = @version.rubygem
      @other_version  = Factory(:version)
      @latest_version = Factory(:version, :rubygem => rubygem)

      Download.incr(rubygem.name, @version.full_name)
      Download.rollover

      5.times  { Download.incr(rubygem.name, @latest_version.full_name) }
      4.times  { Download.incr(rubygem.name, @version.full_name) }
      11.times { Download.incr(@other_version.rubygem.name, @other_version.full_name) }
    end

    should "show overview stats" do
      get :show, :rubygem_id => @version.rubygem.to_param

      assert_equal 2, assigns[:rank]
      assert_equal 3, assigns[:cardinality]
      assert_equal 9, assigns[:downloads_today]
      assert_equal 10, assigns[:downloads_total]
    end

    should "show stats for just a version" do
      get :show, :rubygem_id => @version.rubygem.to_param, :version_id => @version.slug

      assert_equal 3, assigns[:rank]
      assert_equal 3, assigns[:cardinality]
      assert_equal 4, assigns[:downloads_today]
      assert_equal 10, assigns[:downloads_total]
    end

    should "show stats for just the latest version" do
      get :show, :rubygem_id => @version.rubygem.to_param, :version_id => @latest_version.slug

      assert_equal 2, assigns[:rank]
      assert_equal 3, assigns[:cardinality]
      assert_equal 5, assigns[:downloads_today]
      assert_equal 10, assigns[:downloads_total]
    end

    should "show stats for a totally different version" do
      get :show, :rubygem_id => @other_version.rubygem.to_param, :version_id => @other_version.slug

      assert_equal 1, assigns[:rank]
      assert_equal 3, assigns[:cardinality]
      assert_equal 11, assigns[:downloads_today]
      assert_equal 11, assigns[:downloads_total]
    end
  end

  context "On GET to stats for a gem with no versions" do
    setup do
      @rubygem = Factory(:rubygem)
      get :show, :rubygem_id => @rubygem.to_param
    end

    should respond_with :not_found
  end

  context "On GET to stats for nonexistent gem" do
    setup do
      get :show, :rubygem_id => "blahblah"
    end

    should respond_with :not_found
  end

  context "On GET to stats for a specific version" do
    setup do
      @version        = Factory(:version, :number => "0.0.1")
      @rubygem        = @version.rubygem
      @latest_version = Factory(:version, :rubygem => @rubygem, :number => "0.0.2")

      get :show, :rubygem_id => @rubygem.name, :version_id => @version.slug
    end

    should respond_with :success
    should render_template :show
    should assign_to(:rubygem) { @rubygem }
    should assign_to(:version) { @version }
    should assign_to(:versions) { [@version] }
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
    end
    should "see that stats are for this specific version" do
      assert page.has_content?("stats for #{@version.slug}")
    end
  end
end
