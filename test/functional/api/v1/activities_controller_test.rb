require 'test_helper'

class Api::V1::ActivitiesControllerTest < ActionController::TestCase
  context "No signed in-user" do
    context "On GET to latest" do
      setup do
        @rails = create(:rubygem, name: 'rails')
        create(:version, rubygem: @rails)
        create(:version, rubygem: @rails)

        @sinatra = create(:rubygem, name: 'sinatra')
        create(:version, rubygem: @sinatra)

        @foobar = create(:rubygem, name: 'foobar')
        create(:version, rubygem: @foobar)
      end

      should "return correct JSON for latest gems" do
        get :latest, format: :json
        gems = JSON.load @response.body

        assert_equal 2, gems.length
        assert_equal 'foobar', gems[0]['name']
        assert_equal 'sinatra', gems[1]['name']
      end

      should "return correct YAML for latest gems" do
        get :latest, format: :yaml
        gems = YAML.load(@response.body)

        assert_equal 2, gems.length
        assert_equal 'foobar', gems[0]['name']
        assert_equal 'sinatra', gems[1]['name']
      end
    end

    context "On GET to just_updated" do
      setup do
        rails = create(:rubygem, name: 'rails')
        create(:version, rubygem: rails)
        create(:version, rubygem: rails)
        @rails_version = create(:version, rubygem: rails)

        sinatra = create(:rubygem, name: 'sinatra')
        create(:version, rubygem: sinatra)
        @sinatra_version = create(:version, rubygem: sinatra)

        foo = create(:rubygem, name: 'foo')
        create(:version, rubygem: foo)
        @foo_version = create(:version, rubygem: foo)

        # wont show this, as it only has one version
        bar = create(:rubygem, name: 'bar')
        create(:version, rubygem: bar)
      end

      should "return correct JSON for just_updated gems" do
        get :just_updated, format: :json
        gems = JSON.load @response.body
        assert_equal 7, gems.length
        assert_equal 'foo', gems[0]['name']
        assert_equal @foo_version.number, gems[0]['version'], 'should have the latest version'
        assert_equal 'sinatra', gems[2]['name']
        assert_equal @sinatra_version.number, gems[2]['version'], 'should have the latest version'
        assert_equal 'rails', gems[6]['name']
        assert_equal @rails_version.number, gems[6]['version'], 'should have the latest version'
      end

      should "return correct YAML for just_updated gems" do
        get :just_updated, format: :yaml
        gems = YAML.load(@response.body)
        assert_equal 7, gems.length
        assert_equal 'foo', gems[0]['name']
        assert_equal @foo_version.number, gems[0]['version'], 'should have the latest version'
        assert_equal 'sinatra', gems[2]['name']
        assert_equal @sinatra_version.number, gems[2]['version'], 'should have the latest version'
        assert_equal 'rails', gems[6]['name']
        assert_equal @rails_version.number, gems[6]['version'], 'should have the latest version'
      end
    end
  end
end
