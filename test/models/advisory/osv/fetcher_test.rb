# frozen_string_literal: true

require "test_helper"

class Advisory::OSV::FetcherTest < ActiveSupport::TestCase
  setup do
    @document = {
      "id" => "GHSA-mm33-5vfq-3mm3",
      "summary" => "Cross-site Scripting Vulnerability in Action Pack",
      "modified" => "2024-02-18T05:32:29Z",
      "published" => "2022-04-27T22:28:59Z",
      "aliases" => ["CVE-2022-22577"],
      "database_specific" => { "severity" => "MODERATE" },
      "affected" => [
        {
          "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
          "ranges" => ["type" => "ECOSYSTEM", "events" => [{ "introduced" => "5.2.0" }, "fixed" => "5.2.7.1"]]
        },
        {
          "package" => { "name" => "rails", "ecosystem" => "RubyGems" },
          "ranges" => ["type" => "ECOSYSTEM", "events" => [{ "introduced" => "5.2.0" }, "fixed" => "5.2.7.1"]]
        }
      ]
    }
  end

  context "feature flag" do
    should "use the OSV advisories flag" do
      assert_equal FeatureFlag::OSV_ADVISORIES, Advisory::OSV::Fetcher.feature_flag
    end

    should "be disabled by default" do
      refute_predicate Advisory::OSV::Fetcher, :enabled?
    end

    should "be enabled when the flag is on" do
      with_feature FeatureFlag::OSV_ADVISORIES do
        assert_predicate Advisory::OSV::Fetcher, :enabled?
      end
    end
  end

  context "#fetch" do
    should "be left for a later ingest step" do
      assert_raises(NotImplementedError) { Advisory::OSV::Fetcher.new.fetch }
    end
  end

  context "#import" do
    should "upsert one Advisory::OSV row per affected gem" do
      records = Advisory::OSV::Mapper.call(@document)

      assert_equal 2, Advisory::OSV::Fetcher.new.import(records)

      actionpack = Advisory::OSV.find_by!(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "actionpack")
      rails = Advisory::OSV.find_by!(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "rails")

      assert_equal "Cross-site Scripting Vulnerability in Action Pack", actionpack.summary
      assert_equal "moderate", actionpack.severity
      assert_equal ["CVE-2022-22577"], actionpack.aliases
      assert_equal "https://osv.dev/vulnerability/GHSA-mm33-5vfq-3mm3", actionpack.url
      assert_equal ["introduced" => "5.2.0", "fixed" => "5.2.7.1"], actionpack.ranges
      assert_equal "GHSA-mm33-5vfq-3mm3", actionpack.payload["id"]
      assert_equal actionpack.summary, rails.summary
    end

    should "update an existing row on a later import" do
      Advisory::OSV::Fetcher.new.import(Advisory::OSV::Mapper.call(@document))

      updated = @document.merge(
        "summary" => "Updated summary",
        "modified" => "2025-01-01T00:00:00Z",
        "withdrawn" => "2025-01-02T00:00:00Z",
        "database_specific" => { "severity" => "HIGH" }
      )
      Advisory::OSV::Fetcher.new.import(Advisory::OSV::Mapper.call(updated))

      advisory = Advisory::OSV.find_by!(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "actionpack")

      assert_equal 2, Advisory::OSV.where(identifier: "GHSA-mm33-5vfq-3mm3").count
      assert_equal "Updated summary", advisory.summary
      assert_equal "high", advisory.severity
      assert_equal Time.zone.parse("2025-01-01T00:00:00Z"), advisory.modified_at
      assert_equal Time.zone.parse("2025-01-02T00:00:00Z"), advisory.withdrawn_at
    end

    should "allow an advisory for a gem that does not exist yet" do
      Advisory::OSV::Fetcher.new.import(Advisory::OSV::Mapper.call(@document))

      advisory = Advisory::OSV.find_by!(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "actionpack")

      assert_nil advisory.rubygem
    end

    should "return zero when there is nothing to import" do
      assert_equal 0, Advisory::OSV::Fetcher.new.import([])
    end
  end

  context "#sync" do
    should "no-op when the flag is off" do
      fetcher = Advisory::OSV::Fetcher.new
      fetcher.stubs(:fetch).returns([@document])

      fetcher.sync

      assert_empty Advisory::OSV.where(identifier: "GHSA-mm33-5vfq-3mm3")
    end

    should "import fetched documents when the flag is on" do
      fetcher = Advisory::OSV::Fetcher.new
      fetcher.stubs(:fetch).returns([@document])

      with_feature FeatureFlag::OSV_ADVISORIES do
        fetcher.sync
      end

      assert Advisory::OSV.exists?(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "actionpack")
      assert Advisory::OSV.exists?(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "rails")
    end
  end
end
