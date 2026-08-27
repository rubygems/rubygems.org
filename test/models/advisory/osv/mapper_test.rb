# frozen_string_literal: true

require "test_helper"

class Advisory::OSV::MapperTest < ActiveSupport::TestCase
  def document(**overrides)
    {
      "id" => "GHSA-mm33-5vfq-3mm3",
      "summary" => "Cross-site Scripting Vulnerability in Action Pack",
      "modified" => "2024-02-18T05:32:29Z",
      "published" => "2022-04-27T22:28:59Z",
      "aliases" => ["CVE-2022-22577"],
      "database_specific" => { "severity" => "MODERATE" },
      "affected" => [
        "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
        "ranges" => [
          { "type" => "ECOSYSTEM", "events" => [{ "introduced" => "5.2.0" }, "fixed" => "5.2.7.1"] },
          "type" => "ECOSYSTEM", "events" => [{ "introduced" => "6.0.0" }, "last_affected" => "6.0.4.7"]
        ]
      ]
    }.deep_merge(overrides.stringify_keys)
  end

  context "a RubyGems advisory" do
    should "map one row per affected gem with normalized ranges" do
      records = Advisory::OSV::Mapper.call(document)

      assert_equal 1, records.size
      record = records.first

      assert_equal "GHSA-mm33-5vfq-3mm3", record[:identifier]
      assert_equal "actionpack", record[:rubygem_name]
      assert_equal ["CVE-2022-22577"], record[:aliases]
      assert_equal "Cross-site Scripting Vulnerability in Action Pack", record[:summary]
      assert_equal "moderate", record[:severity]
      assert_equal "https://osv.dev/vulnerability/GHSA-mm33-5vfq-3mm3", record[:url]
      assert_equal Time.zone.parse("2022-04-27T22:28:59Z"), record[:published_at]
      assert_equal Time.zone.parse("2024-02-18T05:32:29Z"), record[:modified_at]
      assert_nil record[:withdrawn_at]
      assert_equal [
        { "introduced" => "5.2.0", "fixed" => "5.2.7.1" },
        "introduced" => "6.0.0", "last_affected" => "6.0.4.7"
      ], record[:ranges]
      assert_equal "GHSA-mm33-5vfq-3mm3", record[:payload]["id"]
    end

    should "emit one row per RubyGems package" do
      records = Advisory::OSV::Mapper.call(
        document(
          "affected" => [
            {
              "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
              "ranges" => ["type" => "ECOSYSTEM", "events" => ["introduced" => "0"]]
            },
            {
              "package" => { "name" => "rails", "ecosystem" => "RubyGems" },
              "ranges" => ["type" => "ECOSYSTEM", "events" => ["introduced" => "0"]]
            },
            {
              "package" => { "name" => "actionpack", "ecosystem" => "npm" },
              "ranges" => ["type" => "ECOSYSTEM", "events" => ["introduced" => "1.0.0"]]
            }
          ]
        )
      )

      assert_equal(%w[actionpack rails], records.pluck(:rubygem_name))
      assert(records.all? { |r| r[:identifier] == "GHSA-mm33-5vfq-3mm3" })
    end

    should "merge ranges from multiple affected entries for the same gem" do
      records = Advisory::OSV::Mapper.call(
        document(
          "affected" => [
            {
              "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
              "ranges" => ["type" => "ECOSYSTEM", "events" => [{ "introduced" => "5.2.0" }, "fixed" => "5.2.7.1"]]
            },
            {
              "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
              "ranges" => ["type" => "ECOSYSTEM", "events" => [{ "introduced" => "7.0.0" }, "fixed" => "7.0.2.4"]]
            }
          ]
        )
      )

      assert_equal 1, records.size
      assert_equal [
        { "introduced" => "5.2.0", "fixed" => "5.2.7.1" },
        "introduced" => "7.0.0", "fixed" => "7.0.2.4"
      ], records.first[:ranges]
    end

    should "split a range with multiple introduced/fixed events" do
      records = Advisory::OSV::Mapper.call(
        document(
          "affected" => [
            "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
            "ranges" => [
              "type" => "SEMVER",
              "events" => [
                { "introduced" => "1.0.0" },
                { "fixed" => "1.0.2" },
                { "introduced" => "3.0.0" },
                { "fixed" => "3.2.5" }
              ]
            ]
          ]
        )
      )

      assert_equal [
        { "introduced" => "1.0.0", "fixed" => "1.0.2" },
        { "introduced" => "3.0.0", "fixed" => "3.2.5" }
      ], records.first[:ranges]
    end

    should "skip GIT ranges" do
      records = Advisory::OSV::Mapper.call(
        document(
          "affected" => [
            "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
            "ranges" => [
              { "type" => "GIT", "events" => ["introduced" => "abc123"] },
              "type" => "ECOSYSTEM", "events" => [{ "introduced" => "7.0.0" }, "fixed" => "7.0.1"]
            ]
          ]
        )
      )

      assert_equal ["introduced" => "7.0.0", "fixed" => "7.0.1"], records.first[:ranges]
    end

    should "treat listed versions as exact ranges when ranges are missing" do
      records = Advisory::OSV::Mapper.call(
        document(
          "id" => "MAL-2026-9999",
          "affected" => [
            "package" => { "name" => "zztxtwtmp12", "ecosystem" => "RubyGems" },
            "versions" => ["0.0.1"]
          ]
        )
      )

      assert_equal 1, records.size
      assert_equal "zztxtwtmp12", records.first[:rubygem_name]
      assert_equal ["introduced" => "0.0.1", "last_affected" => "0.0.1"], records.first[:ranges]
    end

    should "use versions when only GIT ranges are present" do
      records = Advisory::OSV::Mapper.call(
        document(
          "affected" => [
            "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
            "ranges" => ["type" => "GIT", "events" => ["introduced" => "abc123"]],
            "versions" => ["7.0.0", "7.0.1"]
          ]
        )
      )

      assert_equal [
        { "introduced" => "7.0.0", "last_affected" => "7.0.0" },
        { "introduced" => "7.0.1", "last_affected" => "7.0.1" }
      ], records.first[:ranges]
    end

    should "prefer ecosystem ranges over versions" do
      records = Advisory::OSV::Mapper.call(
        document(
          "affected" => [
            "package" => { "name" => "actionpack", "ecosystem" => "RubyGems" },
            "ranges" => ["type" => "ECOSYSTEM", "events" => [{ "introduced" => "7.0.0" }, "fixed" => "7.0.1"]],
            "versions" => ["7.0.0"]
          ]
        )
      )

      assert_equal ["introduced" => "7.0.0", "fixed" => "7.0.1"], records.first[:ranges]
    end

    should "set withdrawn_at when the document is withdrawn" do
      records = Advisory::OSV::Mapper.call(document("withdrawn" => "2023-06-01T00:00:00Z"))

      assert_equal Time.zone.parse("2023-06-01T00:00:00Z"), records.first[:withdrawn_at]
    end

    should "fall back to the identifier when summary is missing" do
      records = Advisory::OSV::Mapper.call(document("summary" => nil))

      assert_equal "GHSA-mm33-5vfq-3mm3", records.first[:summary]
    end

    should "leave severity blank when the source value is unknown" do
      records = Advisory::OSV::Mapper.call(document("database_specific" => { "severity" => "SEVERE" }))

      assert_nil records.first[:severity]
    end

    %w[LOW MODERATE HIGH CRITICAL].each do |value|
      should "map #{value} severity" do
        records = Advisory::OSV::Mapper.call(document("database_specific" => { "severity" => value }))

        assert_equal value.downcase, records.first[:severity]
      end
    end
  end

  context "unusable documents" do
    should "return no records without an id" do
      assert_empty Advisory::OSV::Mapper.call(document("id" => nil))
    end

    should "return no records without modified" do
      assert_empty Advisory::OSV::Mapper.call(document("modified" => nil))
    end

    should "return no records when no RubyGems packages are listed" do
      assert_empty Advisory::OSV::Mapper.call(
        document("affected" => ["package" => { "name" => "lodash", "ecosystem" => "npm" }])
      )
    end
  end
end
