require "test_helper"

class StatsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @number_of_gems      = 1337
      @number_of_users     = 101
      @number_of_downloads = 42
      rails_cinco = create(:rubygem, name: "rails_cinco", number: 1)

      Rubygem.expects(:total_count).returns(@number_of_gems)
      User.expects(:count).returns(@number_of_users)

      create(:gem_download, count: @number_of_downloads)
      rails_cinco.gem_download.update(count: 1)

      get :index
    end

    should respond_with :success

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
  end

  context "on GET to index with no downloads" do
    setup do
      get :index
    end

    should respond_with :success
  end

  context "on GET to index with multiple gems" do
    setup do
      create(:gem_download, count: 0)
      rg1 = create(:rubygem, downloads: 10, number: "1")
      rg2 = create(:rubygem, downloads: 20, number: "1")
      rg3 = create(:rubygem, downloads: 30, number: "1")
      n = 10
      data = [rg1, rg2, rg3].map { |r| [r.versions.last.full_name, n += 10] }
      GemDownload.bulk_update(data)

      get :index
    end

    should "not have width greater than 100%" do
      assert_select ".stats__graph__gem__meter" do |element|
        element.pluck(:style).each do |width|
          width =~ /width: (\d+[,.]\d+)%/
          assert Regexp.last_match(1).to_f <= 100, "#{Regexp.last_match(1)} is greater than 100"
        end
      end
    end
  end
end
