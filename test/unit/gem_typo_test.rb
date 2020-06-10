require "test_helper"

class GemTypoTest < ActiveSupport::TestCase
  setup do
    existing = create(:rubygem, name: "delayed_job_active_record")
    existing.versions.create(number: "1.0.0", platform: "ruby")
    existing.versions.create(number: "1.0.1", platform: "ruby")

    deleted = create(:rubygem, name: "deleted_job_active_record")
    deleted.versions.create(number: "1.0.0", platform: "ruby",yanked_at: Time.now.utc)
  end

  should "return false for exact match" do
    gem_typo = GemTypo.new("delayed_job_active_record")
    refute gem_typo.protected_typo?
  end

  should "return false for any exact match so that owner of the existing delayed_job_active_record Gem can push an update even though there is an existing typo squat delayed-job-active-record that would otherwise block the update" do
   gem_typo = GemTypo.new("delayed_job_active_record")
   refute gem_typo.protected_typo?
  end

  should "return false for an exact match of a yanked gem so a gem with an identical name can be published in the future" do
    gem_typo = GemTypo.new("deleted_job_active_record")
    refute gem_typo.protected_typo?
  end

  should "return false for a underscore variation match of a yanked gem so a gem with a similar name can be published in the future" do
    gem_typo = GemTypo.new("deleted-job-active_record")
    refute gem_typo.protected_typo?
  end

  context "typo squat on an existing Gem name" do
    should "return true for one -/_ character change" do
      gem_typo = GemTypo.new("delayed-job_active_record")
      assert gem_typo.protected_typo?
    end

    should "return true for two -/_ change" do
      gem_typo = GemTypo.new("delayed-job_active-record")
      assert gem_typo.protected_typo?
    end

    should "return true for three -/_ character change" do
      gem_typo = GemTypo.new("delayed-job-active-record")
      assert gem_typo.protected_typo?
    end
  end
end
