require 'test_helper'

class StatsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @number_of_gems      = 1337
      @number_of_users     = 101
      @number_of_downloads = 42
      @most_downloaded     = [create(:rubygem)]

      Rubygem.stubs(:total_count).returns @number_of_gems
      Download.stubs(:count).returns @number_of_downloads
      Rubygem.stubs(:downloaded).returns @most_downloaded
      User.stubs(:count).returns @number_of_users

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
      assert_received(User, :count)
      assert_received(Rubygem, :total_count)
      assert_received(Download, :count)
      assert_received(Rubygem, :downloaded) { |subject| subject.with(10) }
    end
  end

  context "on GET to index with multiple gems" do
    setup do
      rg1 = create(:rubygem, downloads: 10, number: "1")
      def rg1.downloads; 10; end
      rg2 = create(:rubygem, downloads: 20, number: "1")
      def rg2.downloads; 50; end
      rg3 = create(:rubygem, downloads: 30, number: "1")
      def rg3.downloads; 30; end

      Rubygem.stubs(:downloaded).returns [rg1, rg2, rg3]

      get :index
    end

    should "not have width greater than 100%" do
      assert_select ".stats__graph__gem__meter" do |element|
        element.map { |h| h[:style] }.each do |width|
          width =~ /width\: (\d+[,.]\d+)%/
          assert $1.to_f <= 100, "#{$1} is greater than 100"
        end
      end
    end
  end
end
