require "test_helper"

class GemTypoTest < ActiveSupport::TestCase
  setup do
    existing = create(:rubygem, name: "delayed_job_active_record")
    existing.versions.create(number: '1.0.0', platform: 'ruby')
    existing.versions.create(number: '1.0.1', platform: 'ruby')
  end

  should "return false for exact match" do
    gem_typo = GemTypo.new("delayed_job_active_record")
    assert_equal false, gem_typo.protected_typo?
  end

  should "return false for any exact match" do
    existing_typo = build(:rubygem, name: "delayed-job-active-record")
    existing_typo.save(validate: false)
    existing_typo.versions.create(number: '1.0.1', platform: 'ruby')

    gem_typo = GemTypo.new("delayed_job_active_record")
    assert_equal false, gem_typo.protected_typo?
  end

  context "typo squat on an existing Gem name" do
    should "return true for one -/_ character change" do
      gem_typo = GemTypo.new("delayed-job_active_record")
      assert_equal true, gem_typo.protected_typo?
    end

    should "return true for two -/_ change" do
      gem_typo = GemTypo.new("delayed-job_active_record")
      assert_equal true, gem_typo.protected_typo?
    end

    should "return true for three -/_ character change" do
      gem_typo = GemTypo.new("delayed-job-active-record")
      assert_equal true, gem_typo.protected_typo?
    end
  end
end
