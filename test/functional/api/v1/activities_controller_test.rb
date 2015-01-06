require 'test_helper'

class Api::V1::ActivitiesControllerTest < ActionController::TestCase

  def should_return_latest_gems(gems)
    assert_equal 2, gems.length
    gems.each {|g| assert g.is_a?(Hash) }
    assert_equal @rubygem_2.attributes['name'], gems[0]['name']
    assert_equal @rubygem_3.attributes['name'], gems[1]['name']
  end

  def should_return_just_updated_gems(gems)
    assert_equal 3, gems.length
    gems.each {|g| assert g.is_a?(Hash) }
    assert_equal @rubygem_1.attributes['name'], gems[0]['name']
    assert_equal @rubygem_2.attributes['name'], gems[1]['name']
    assert_equal @rubygem_3.attributes['name'], gems[2]['name']
  end

  def should_return_paginated_just_updated_gems(gems)
    assert_equal 3, gems.length
    gems.each {|g| assert g.is_a?(Hash) }
    assert_equal @rubygem_3.attributes['name'], gems[0]['name']
    assert_equal @rubygem_2.attributes['name'], gems[1]['name']
    assert_equal @rubygem_1.attributes['name'], gems[2]['name']
  end

  context "No signed in-user" do
    context "On GET to latest" do
      setup do
        @rubygem_1 = create(:rubygem)
        @version_1 = create(:version, :rubygem => @rubygem_1)
        @version_2 = create(:version, :rubygem => @rubygem_1)

        @rubygem_2 = create(:rubygem)
        @version_3 = create(:version, :rubygem => @rubygem_2)

        @rubygem_3 = create(:rubygem)
        @version_4 = create(:version, :rubygem => @rubygem_3)

        stub(Rubygem).latest(50){ [@rubygem_2, @rubygem_3] }
      end

      should "return correct JSON for latest gems" do
        get :latest, :format => :json
        should_return_latest_gems MultiJson.load(@response.body)
      end

      should "return correct YAML for latest gems" do
        get :latest, :format => :yaml
        should_return_latest_gems YAML.load(@response.body)
      end

      should "return correct XML for latest gems" do
        get :latest, :format => :xml
        gems = Hash.from_xml(Nokogiri.parse(@response.body).to_xml)['rubygems']
        should_return_latest_gems(gems)
      end
    end

    context "On GET to just_updated" do
      setup do
        @rubygem_1 = create(:rubygem)
        @version_1 = create(:version, :rubygem => @rubygem_1)
        @version_2 = create(:version, :rubygem => @rubygem_1)

        @rubygem_2 = create(:rubygem)
        @version_3 = create(:version, :rubygem => @rubygem_2)

        @rubygem_3 = create(:rubygem)
        @version_4 = create(:version, :rubygem => @rubygem_3)

        stub(Version).just_updated { subject }
        stub(subject).paginate(:page => nil, :per_page => 50){ [@version_2, @version_3, @version_4] }
        stub(subject).paginate(:page => 2, :per_page => 50){ [@version_4, @version_3, @version_2] }
      end

      should "return correct JSON for just_updated gems" do
        get :just_updated, :format => :json
        should_return_just_updated_gems MultiJson.load(@response.body)
      end

      should "return correct YAML for just_updated gems" do
        get :just_updated, :format => :yaml
        should_return_just_updated_gems YAML.load(@response.body)
      end

      should "return correct XML for just_updated gems" do
        get :just_updated, :format => :xml
        gems = Hash.from_xml(Nokogiri.parse(@response.body).to_xml)['rubygems']
        should_return_just_updated_gems(gems)
      end

      should "support a page parameter" do
        get :just_updated, :page => 2, :format => :json
        should_return_paginated_just_updated_gems MultiJson.load(@response.body)
      end
    end

  end
end
