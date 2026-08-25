# frozen_string_literal: true

require "test_helper"

class SyncAdvisoriesJobTest < ActiveJob::TestCase
  setup do
    @document = {
      "id" => "GHSA-test-0001-0001",
      "summary" => "Example",
      "modified" => "2024-01-02T00:00:00Z",
      "published" => "2024-01-01T00:00:00Z",
      "aliases" => ["CVE-2024-0001"],
      "database_specific" => { "severity" => "HIGH" },
      "affected" => [
        "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
        "ranges" => [
          "type" => "ECOSYSTEM", "events" => [{ "introduced" => "7.0.0" }, "fixed" => "7.0.2.4"]
        ]
      ]
    }
  end

  context "#perform" do
    should "not sync when fetcher flags are off" do
      Advisory::OSV::Fetcher.any_instance.expects(:sync).never

      SyncAdvisoriesJob.perform_now
    end

    should "sync enabled fetchers" do
      Advisory::OSV::Fetcher.any_instance.stubs(:fetch).returns([@document])

      with_feature FeatureFlag::OSV_ADVISORIES do
        SyncAdvisoriesJob.perform_now
      end

      assert Advisory::OSV.exists?(identifier: "GHSA-test-0001-0001", rubygem_name: "actionpack")
    end
  end
end
