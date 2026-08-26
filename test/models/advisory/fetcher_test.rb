# frozen_string_literal: true

require "test_helper"

class Advisory::FetcherTest < ActiveSupport::TestCase
  class FakeFetcher < Advisory::Fetcher
    attr_writer :documents

    def self.feature_flag = :fake_advisories
    def self.advisory_class = Advisory::OSV

    def fetch
      @documents
    end

    def map(document)
      Advisory::OSV::Mapper.call(document)
    end
  end

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

  context ".all" do
    should "include the OSV fetcher" do
      assert_includes Advisory::Fetcher.all, Advisory::OSV::Fetcher
    end
  end

  context ".enabled" do
    should "exclude fetchers whose flag is off" do
      refute_includes Advisory::Fetcher.enabled, Advisory::OSV::Fetcher
    end

    should "include fetchers whose flag is on" do
      with_feature FeatureFlag::OSV_ADVISORIES do
        assert_includes Advisory::Fetcher.enabled, Advisory::OSV::Fetcher
      end
    end
  end

  context ".sync_all" do
    should "not sync when the fetcher flag is off" do
      Advisory::OSV::Fetcher.any_instance.expects(:sync).never

      Advisory::Fetcher.sync_all
    end

    should "sync enabled fetchers" do
      Advisory::OSV::Fetcher.any_instance.stubs(:fetch).returns([@document])

      with_feature FeatureFlag::OSV_ADVISORIES do
        Advisory::Fetcher.sync_all
      end

      assert Advisory::OSV.exists?(identifier: "GHSA-test-0001-0001", rubygem_name: "actionpack")
    end

    should "sync all fetchers when forced even if flags are off" do
      Advisory::OSV::Fetcher.any_instance.stubs(:fetch).returns([@document])

      Advisory::Fetcher.sync_all(force: true)

      assert Advisory::OSV.exists?(identifier: "GHSA-test-0001-0001", rubygem_name: "actionpack")
    end
  end

  context "#sync" do
    should "not fetch or import when the flag is off" do
      fetcher = FakeFetcher.new
      fetcher.documents = [@document]
      fetcher.expects(:fetch).never

      fetcher.sync

      assert_empty Advisory::OSV.where(identifier: "GHSA-test-0001-0001")
    end

    should "import when forced even if the flag is off" do
      fetcher = FakeFetcher.new
      fetcher.documents = [@document]

      fetcher.sync(force: true)

      assert Advisory::OSV.exists?(identifier: "GHSA-test-0001-0001", rubygem_name: "actionpack")
    end

    should "import mapped documents when the flag is on" do
      fetcher = FakeFetcher.new
      fetcher.documents = [@document]

      with_feature :fake_advisories do
        fetcher.sync
      end

      advisory = Advisory::OSV.find_by!(identifier: "GHSA-test-0001-0001", rubygem_name: "actionpack")

      assert_equal "Example", advisory.summary
      assert_equal "high", advisory.severity
      assert_equal ["introduced" => "7.0.0", "fixed" => "7.0.2.4"], advisory.ranges
    end
  end

  context "#download" do
    setup do
      @url = "https://example.test/advisories"
    end

    should "return the response body" do
      stub_request(:get, @url).to_return(status: 200, body: "ok")

      assert_equal "ok", FakeFetcher.new.download(@url)
    end

    should "retry a failed GET and succeed" do
      stub_request(:get, @url).to_return(status: 500, body: "nope").then.to_return(status: 200, body: "ok")

      assert_equal "ok", FakeFetcher.new.download(@url)
      assert_requested :get, @url, times: 2
    end
  end

  context "abstract interface" do
    should "require subclasses to define feature_flag" do
      assert_raises(NotImplementedError) { Advisory::Fetcher.feature_flag }
    end

    should "require subclasses to define advisory_class" do
      assert_raises(NotImplementedError) { Advisory::Fetcher.advisory_class }
    end

    should "require subclasses to implement fetch" do
      assert_raises(NotImplementedError) { Advisory::Fetcher.new.fetch }
    end

    should "require subclasses to implement map" do
      assert_raises(NotImplementedError) { Advisory::Fetcher.new.map({}) }
    end
  end
end
