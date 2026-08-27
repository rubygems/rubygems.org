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
    should "follow Advisory::OSV" do
      refute_predicate Advisory::OSV::Fetcher, :enabled?
    end

    should "be enabled when the advisory source is enabled" do
      with_feature FeatureFlag::OSV_ADVISORIES do
        assert_predicate Advisory::OSV::Fetcher, :enabled?
      end
    end
  end

  context "#fetch" do
    context "when no advisories exist" do
      should "parse JSON documents from the OSV RubyGems dump" do
        other = @document.merge("id" => "GHSA-other-0000-0000", "summary" => "Other")
        stub_osv_dump([@document, other])

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal %w[GHSA-mm33-5vfq-3mm3 GHSA-other-0000-0000], documents.pluck("id")
        assert_equal "Cross-site Scripting Vulnerability in Action Pack", documents.first["summary"]
        assert_not_requested :get, Advisory::OSV::Fetcher::INDEX_URL
      end

      should "skip nested paths, non-JSON files, and invalid JSON" do
        stub_osv_dump(
          [@document],
          extra: {
            "nested/GHSA-nested-0000-0000.json" => { "id" => "GHSA-nested-0000-0000" }.to_json,
            "README.md" => "not json",
            "GHSA-bad-0000-0000.json" => "{not json}"
          }
        )

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal ["GHSA-mm33-5vfq-3mm3"], documents.pluck("id")
      end

      should "raise when the dump HTTP request fails" do
        stub_request(:get, Advisory::OSV::Fetcher::DUMP_URL).to_return(status: 500, body: "nope")

        assert_raises(Faraday::ServerError) { Advisory::OSV::Fetcher.new.fetch }
        assert_requested :get, Advisory::OSV::Fetcher::DUMP_URL, times: 3
      end

      should "raise when the dump is not a zip" do
        stub_request(:get, Advisory::OSV::Fetcher::DUMP_URL).to_return(status: 200, body: "not a zip")

        error = assert_raises(Advisory::Fetcher::Error) { Advisory::OSV::Fetcher.new.fetch }

        assert_match(/Invalid OSV dump archive/, error.message)
      end

      should "raise when a dump entry is too large" do
        stub_osv_dump([@document])

        stub_const(Advisory::OSV::Fetcher, :MAX_ENTRY_BYTES, 1) do
          error = assert_raises(Advisory::Fetcher::Error) { Advisory::OSV::Fetcher.new.fetch }

          assert_match(/OSV dump entry too large/, error.message)
        end
      end

      should "send an identifying user agent" do
        stub_osv_dump([@document])

        Advisory::OSV::Fetcher.new.fetch

        assert_requested :get, Advisory::OSV::Fetcher::DUMP_URL, headers: {
          "User-Agent" => "RubyGems.org Advisory Fetcher/#{AppRevision.version}"
        }
      end
    end

    context "when advisories already exist" do
      setup do
        create(:advisory, identifier: "GHSA-old-0000-0000", modified_at: Time.zone.parse("2026-01-01T00:00:00Z"))
      end

      should "fetch JSON records at or after the latest modified_at" do
        newer = @document.merge("id" => "GHSA-new-0000-0000", "modified" => "2026-02-01T00:00:00Z")
        watermark = @document.merge("id" => "GHSA-old-0000-0000", "modified" => "2026-01-01T00:00:00Z")
        stub_osv_index(
          ["2026-02-01T00:00:00Z", newer["id"]],
          ["2026-01-01T00:00:00Z", watermark["id"]],
          ["2025-12-01T00:00:00Z", "GHSA-older-0000-0000"]
        )
        stub_osv_document(newer)
        stub_osv_document(watermark)

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [newer["id"], watermark["id"]], documents.pluck("id")
        assert_not_requested :get, Advisory::OSV::Fetcher::DUMP_URL
        assert_not_requested :get, osv_document_url("GHSA-older-0000-0000")
      end

      should "re-fetch records that share the latest modified_at" do
        sibling = @document.merge("id" => "GHSA-same-0000-0000", "modified" => "2026-01-01T00:00:00Z")
        watermark = @document.merge("id" => "GHSA-old-0000-0000", "modified" => "2026-01-01T00:00:00Z")
        stub_osv_index(
          ["2026-01-01T00:00:00Z", sibling["id"]],
          ["2026-01-01T00:00:00Z", watermark["id"]],
          ["2025-12-01T00:00:00Z", "GHSA-older-0000-0000"]
        )
        stub_osv_document(sibling)
        stub_osv_document(watermark)

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [sibling["id"], watermark["id"]], documents.pluck("id")
        assert_not_requested :get, osv_document_url("GHSA-older-0000-0000")
      end

      should "not fetch records older than the latest modified_at" do
        watermark = @document.merge("id" => "GHSA-old-0000-0000", "modified" => "2026-01-01T00:00:00Z")
        stub_osv_index(
          ["2026-01-01T00:00:00Z", watermark["id"]],
          ["2025-12-01T00:00:00Z", "GHSA-older-0000-0000"]
        )
        stub_osv_document(watermark)

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [watermark["id"]], documents.pluck("id")
        assert_not_requested :get, Advisory::OSV::Fetcher::DUMP_URL
        assert_not_requested :get, osv_document_url("GHSA-older-0000-0000")
      end

      should "keep path-like identifiers inside the RubyGems prefix" do
        stub_osv_index(["2026-02-01T00:00:00Z", "../escape"])
        stub_request(:get, "#{Advisory::OSV::Fetcher::BASE_URL}/#{CGI.escapeURIComponent('../escape')}.json")
          .to_return(status: 404, body: "missing")
        stub_osv_dump([@document])

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [@document["id"]], documents.pluck("id")
        assert_not_requested :get, "https://osv-vulnerabilities.storage.googleapis.com/escape.json"
      end

      should "fall back to the full dump when too many records changed" do
        stub_osv_index(
          ["2026-03-01T00:00:00Z", "GHSA-new-0000-0001"],
          ["2026-02-01T00:00:00Z", @document["id"]]
        )
        stub_osv_dump([@document])

        stub_const(Advisory::OSV::Fetcher, :MAX_INCREMENTAL_IDS, 1) do
          documents = Advisory::OSV::Fetcher.new.fetch

          assert_equal [@document["id"]], documents.pluck("id")
        end

        assert_requested :get, Advisory::OSV::Fetcher::DUMP_URL
        assert_not_requested :get, osv_document_url(@document["id"])
        assert_not_requested :get, osv_document_url("GHSA-new-0000-0001")
      end

      should "fall back to the full dump when an incremental document is missing" do
        stub_osv_index(
          ["2026-02-01T00:00:00Z", "GHSA-new-0000-0000"],
          ["2026-01-15T00:00:00Z", "GHSA-other-0000-0000"]
        )
        stub_request(:get, osv_document_url("GHSA-new-0000-0000")).to_return(status: 404, body: "missing")
        stub_osv_dump([@document])

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [@document["id"]], documents.pluck("id")
        assert_requested :get, Advisory::OSV::Fetcher::DUMP_URL
        assert_not_requested :get, osv_document_url("GHSA-other-0000-0000")
      end

      should "fall back to the full dump when an incremental document is invalid JSON" do
        stub_osv_index(["2026-02-01T00:00:00Z", "GHSA-new-0000-0000"])
        stub_request(:get, osv_document_url("GHSA-new-0000-0000")).to_return(status: 200, body: "{not json}")
        stub_osv_dump([@document])

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [@document["id"]], documents.pluck("id")
        assert_requested :get, Advisory::OSV::Fetcher::DUMP_URL
      end

      should "fall back to the full dump when the index request fails" do
        stub_request(:get, Advisory::OSV::Fetcher::INDEX_URL).to_return(status: 500, body: "nope")
        stub_osv_dump([@document])

        documents = Advisory::OSV::Fetcher.new.fetch

        assert_equal [@document["id"]], documents.pluck("id")
        assert_requested :get, Advisory::OSV::Fetcher::DUMP_URL
      end
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

    should "download the OSV dump and import mapped rows" do
      stub_osv_dump([@document])

      with_feature FeatureFlag::OSV_ADVISORIES do
        Advisory::OSV::Fetcher.new.sync
      end

      assert Advisory::OSV.exists?(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "actionpack")
      assert Advisory::OSV.exists?(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "rails")
    end

    should "import only updated documents on a later sync" do
      Advisory::OSV::Fetcher.new.import(Advisory::OSV::Mapper.call(@document))
      updated = @document.merge("summary" => "Updated from OSV", "modified" => "2026-03-01T00:00:00Z")
      stub_osv_index(["2026-03-01T00:00:00Z", updated["id"]])
      stub_osv_document(updated)

      with_feature FeatureFlag::OSV_ADVISORIES do
        Advisory::OSV::Fetcher.new.sync
      end

      advisory = Advisory::OSV.find_by!(identifier: "GHSA-mm33-5vfq-3mm3", rubygem_name: "actionpack")

      assert_equal "Updated from OSV", advisory.summary
      assert_not_requested :get, Advisory::OSV::Fetcher::DUMP_URL
    end
  end

  private

  def stub_osv_dump(documents, extra: {})
    files = documents.to_h { |doc| ["#{doc.fetch('id')}.json", doc.to_json] }.merge(extra)
    stub_request(:get, Advisory::OSV::Fetcher::DUMP_URL).to_return(
      status: 200,
      body: osv_dump_zip(files),
      headers: { "Content-Type" => "application/zip" }
    )
  end

  def stub_osv_index(*rows)
    body = rows.map { |modified, id| "#{modified},#{id}" }.join("\n")
    stub_request(:get, Advisory::OSV::Fetcher::INDEX_URL).to_return(
      status: 200,
      body: body,
      headers: { "Content-Type" => "text/csv" }
    )
  end

  def stub_osv_document(document)
    stub_request(:get, osv_document_url(document.fetch("id"))).to_return(
      status: 200,
      body: document.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def osv_document_url(id)
    "#{Advisory::OSV::Fetcher::BASE_URL}/#{id}.json"
  end

  def osv_dump_zip(files)
    Zip::OutputStream.write_buffer do |zio|
      files.each do |name, content|
        zio.put_next_entry(name)
        zio.write(content)
      end
    end.string
  end
end
