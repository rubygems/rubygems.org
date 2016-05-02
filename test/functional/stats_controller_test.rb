require 'test_helper'

class StatsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @number_of_gems      = 1337
      @number_of_users     = 101
      @number_of_downloads = 42
      rails_cinco = create(:rubygem, name: 'rails_cinco', number: 1)

      Rubygem.stubs(:total_count).returns @number_of_gems
      User.stubs(:count).returns @number_of_users

      create(:gem_download, count: @number_of_downloads)
      rails_cinco.gem_download.update(count: 1)

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

    should "display the top gem" do
      assert page.has_content?("rails_cinco")
    end

    should "load up the number of gems, users, and downloads" do
      assert_received(User, :count)
      assert_received(Rubygem, :total_count)
    end
  end

  context "on GET to index with no downloads" do
    setup do
      get :index
    end

    should respond_with :success
  end

  context "on GET to index with multiple gems" do
    setup do
      rg1 = create(:rubygem, downloads: 10, number: "1")
      rg2 = create(:rubygem, downloads: 20, number: "1")
      rg3 = create(:rubygem, downloads: 30, number: "1")
      n = 10
      [rg1, rg2, rg3].each do |rg|
        rg.versions.last.gem_download.update(count: n)
        n += 10
      end

      get :index
    end

    should "not have width greater than 100%" do
      assert_select ".stats__graph__gem__meter" do |element|
        element.map { |h| h[:style] }.each do |width|
          width =~ /width\: (\d+[,.]\d+)%/
          assert Regexp.last_match(1).to_f <= 100, "#{Regexp.last_match(1)} is greater than 100"
        end
      end
    end
  end
end
