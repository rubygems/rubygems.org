# frozen_string_literal: true

require "test_helper"

class Api::V1::ActivitiesControllerTest < ActionController::TestCase
  context "No signed in-user" do
    context "On GET to latest" do
      setup do
        @rails = create(:rubygem, name: "rails", created_at: 3.days.ago)
        create(:version, rubygem: @rails)
        create(:version, rubygem: @rails)

        @sinatra = create(:rubygem, name: "sinatra", created_at: 2.days.ago)
        create(:version, rubygem: @sinatra)

        @foobar = create(:rubygem, name: "foobar", created_at: 1.day.ago)
        create(:version, rubygem: @foobar,
               dependencies: [build(:dependency, rubygem: @rails), build(:dependency, rubygem: @sinatra)])
      end

      should "return correct JSON for latest gems" do
        get :latest, format: :json
        gems = JSON.load @response.body

        assert_equal 3, gems.length
        assert_equal "foobar", gems[0]["name"]
        assert_equal "sinatra", gems[1]["name"]
        assert_equal "rails", gems[2]["name"]
      end

      should "return correct YAML for latest gems" do
        get :latest, format: :yaml
        gems = YAML.safe_load(@response.body)

        assert_equal 3, gems.length
        assert_equal "foobar", gems[0]["name"]
        assert_equal "sinatra", gems[1]["name"]
        assert_equal "rails", gems[2]["name"]
      end

      should "exclude gems with only prerelease versions" do
        prerelease_gem = create(:rubygem, name: "beta_only")
        create(:version, rubygem: prerelease_gem, number: "1.0.0.beta1")

        get :latest, format: :json
        gems = JSON.load @response.body
        gem_names = gems.map { |g| g["name"] }

        assert_not_includes gem_names, "beta_only"
      end
    end

    context "On GET to just_updated" do
      setup do
        rails = create(:rubygem, name: "rails")
        sinatra = create(:rubygem, name: "sinatra")
        foo = create(:rubygem, name: "foo")
        bar = create(:rubygem, name: "bar")

        create(:version, rubygem: rails)
        create(:version, rubygem: sinatra)
        @sinatra_version = create(:version, rubygem: sinatra)
        create(:version, rubygem: foo)
        @foo_version = create(:version, rubygem: foo)
        @rails_version = create(:version, rubygem: rails)
        # wont show this, as it only has one version
        create(:version, rubygem: bar)
      end

      should "return correct JSON for just_updated gems" do
        get :just_updated, format: :json
        gems = JSON.load @response.body

        assert_equal 6, gems.length
        assert_equal "rails", gems[0]["name"]
        assert_equal @rails_version.number, gems[0]["version"], "should have the latest version"
        assert_equal "foo", gems[1]["name"]
        assert_equal @foo_version.number, gems[1]["version"], "should have the latest version"
        assert_equal "sinatra", gems[3]["name"]
        assert_equal @sinatra_version.number, gems[3]["version"], "should have the latest version"
      end

      should "return correct YAML for just_updated gems" do
        get :just_updated, format: :yaml
        gems = YAML.safe_load(@response.body)

        assert_equal 6, gems.length
        assert_equal "rails", gems[0]["name"]
        assert_equal @rails_version.number, gems[0]["version"], "should have the latest version"
        assert_equal "foo", gems[1]["name"]
        assert_equal @foo_version.number, gems[1]["version"], "should have the latest version"
        assert_equal "sinatra", gems[3]["name"]
        assert_equal @sinatra_version.number, gems[3]["version"], "should have the latest version"
      end
    end
  end
end
