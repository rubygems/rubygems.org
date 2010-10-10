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
      assert_contain "1,337"
    end

    should "display number of users" do
      assert_contain "101"
    end

    should "display number of downloads" do
      assert_contain "42"
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
      assert_contain @rubygem.name
    end
    should "display a dropdown to choose the version to show" do
      assert_have_no_selector 'select#version_for_stats'
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
      assert_have_selector 'select#version_for_stats'
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
      assert_contain @rubygem.name
    end
  end
end
