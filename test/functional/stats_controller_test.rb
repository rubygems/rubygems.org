require 'test_helper'

class StatsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @number_of_gems      = 1337
      @number_of_users     = 101
      @number_of_downloads = 42
      @most_downloaded     = [create(:rubygem)]

      stub(Rubygem).total_count { @number_of_gems }
      stub(Download).count { @number_of_downloads }
      stub(Rubygem).downloaded { @most_downloaded }
      stub(User).count { @number_of_users }

      get :index
    end

    should respond_with :success
    should render_template :index

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
end
