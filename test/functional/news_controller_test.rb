# frozen_string_literal: true

require 'test_helper'

class NewsControllerTest < ActionController::TestCase
  setup do
    @rubygem1 = create(:rubygem, downloads: 10)
    @rubygem2 = create(:rubygem, downloads: 20)
    @rubygem3 = create(:rubygem, downloads: 30)
    create(:version, rubygem: @rubygem2, created_at: 5.days.ago)
    create(:version, rubygem: @rubygem3, created_at: 6.days.ago)
    create(:version, rubygem: @rubygem1, created_at: 59.days.ago)
  end

  context "on GET to show" do
    setup do
      get :show
    end

    should "not include gems updated since 7 days" do
      refute page.has_content? @rubygem1.name
    end

    should "order by created_at of gem version" do
      expected_order = [@rubygem2, @rubygem3]

      assert_select("a.gems__gem > span > h2").each_with_index do |element, index|
        assert_match(/#{expected_order[index].name}/, element.text)
      end
    end

    should "display entries and total in page info" do
      assert_select "header > p.gems__meter", text: /.*10 of 100 in total/
    end
  end

  context "on GET to popular" do
    setup do
      @rubygem4 = create(:rubygem, downloads: 20)
      create(:version, rubygem: @rubygem4, created_at: 71.days.ago)
      get :popular
    end

    should "not include gems updated since 70 days" do
      refute page.has_content? @rubygem4.name
    end

    should "order by gem downloads" do
      expected_order = [@rubygem3, @rubygem2, @rubygem1]

      assert_select("a.gems__gem > span > h2").each_with_index do |element, index|
        assert_match(/#{expected_order[index].name}/, element.text)
      end
    end

    should "display entries and total in page info" do
      assert_select "header > p.gems__meter", text: /.*10 of 100 in total/
    end
  end
end
