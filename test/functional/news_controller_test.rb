require "test_helper"

class NewsControllerTest < ActionController::TestCase
  setup do
    @rubygem1 = create(:rubygem, downloads: 10)
    @rubygem2 = create(:rubygem, downloads: 20)
    @rubygem3 = create(:rubygem, downloads: 30)
    create(:version, rubygem: @rubygem2, created_at: (Gemcutter::NEWS_DAYS_LIMIT - 2.days).ago)
    create(:version, rubygem: @rubygem3, created_at: (Gemcutter::NEWS_DAYS_LIMIT - 1.day).ago)
    create(:version, rubygem: @rubygem1, created_at: (Gemcutter::NEWS_DAYS_LIMIT + 1.day).ago)
  end

  context "on GET to show" do
    setup do
      get :show
    end

    should "not include gems updated prior to Gemcutter::NEWS_DAYS_LIMIT days ago" do
      refute page.has_content? @rubygem1.name
    end

    should "order by created_at of gem version" do
      expected_order = [@rubygem2, @rubygem3].map(&:name)
      actual_order = assert_select("h2.gems__gem__name").map(&:text)

      expected_order.each_with_index do |expected_gem_name, i|
        assert_match(/#{expected_gem_name}/, actual_order[i])
      end
    end

    should "display entries and total in page info" do
      assert_select "header > p.gems__meter", text: /.*2 of 100 in total/
    end
  end

  context "on GET to popular" do
    setup do
      @rubygem4 = create(:rubygem, downloads: 20)
      create(:version, rubygem: @rubygem4, created_at: (Gemcutter::POPULAR_DAYS_LIMIT + 1.day).ago)
      get :popular
    end

    should "not include gems updated prior to Gemcutter::POPULAR_DAYS_LIMIT days ago" do
      refute page.has_content? @rubygem4.name
    end

    should "order by gem downloads" do
      expected_order = [@rubygem3, @rubygem2, @rubygem1].map(&:name)
      actual_order = assert_select("h2.gems__gem__name").map(&:text)

      expected_order.each_with_index do |expected_gem_name, i|
        assert_match(/#{expected_gem_name}/, actual_order[i])
      end
    end

    should "display entries and total in page info" do
      assert_select "header > p.gems__meter", text: /.*3 of 100 in total/
    end
  end

  context "with multiple latest versions on different platforms" do
    setup do
      Gemcutter::NEWS_PER_PAGE.times do |i|
        create(:version, rubygem: @rubygem2,
          created_at: (Gemcutter::NEWS_DAYS_LIMIT - 2.days).ago, platform: "platform#{i}")
      end
      get :show
    end

    should "display expected entries" do
      expected_order = [@rubygem2, @rubygem3].map(&:name)
      actual_order = assert_select("h2.gems__gem__name").map(&:text)

      expected_order.each_with_index do |expected_gem_name, i|
        assert_match(/#{expected_gem_name}/, actual_order[i])
      end
    end
  end
end
