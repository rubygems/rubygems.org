# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillSpecSha256TaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return versions without spec_sha256" do
      create(:version)
      b = create(:version, spec_sha256: nil)
      create(:version, spec_sha256: nil, indexed: false)

      assert_equal [b], Maintenance::BackfillSpecSha256Task.collection.to_a
    end
  end

  context "#process" do
    setup do
      @rubygem = create(:rubygem, name: "rubygem")
    end

    teardown do
      RubygemFs.mock!
    end

    should "update the spec sha256" do
      RubygemFs.instance.store("quick/Marshal.4.8/rubygem-1.gemspec.rz", "spec contents")

      v = create(:version, rubygem: @rubygem, number: "1", platform: "ruby", spec_sha256: nil)
      Maintenance::BackfillSpecSha256Task.process(v)

      assert_equal "Ry6N90Xp7Or9qGoWziaaTotD1K7vOAonnRAAPjXCzic=", v.reload.spec_sha256
    end

    should "error if spec is missing" do
      v = create(:version, rubygem: @rubygem, number: "1", platform: "ruby", spec_sha256: nil)
      e = assert_raise { Maintenance::BackfillSpecSha256Task.process(v) }

      assert_equal "quick/Marshal.4.8/rubygem-1.gemspec.rz is missing", e.message
    end

    should "not update the spec sha256 if it is already set" do
      RubygemFs.instance.store("quick/Marshal.4.8/rubygem-1.gemspec.rz", "spec contents")

      v = create(:version, rubygem: @rubygem, number: "1", platform: "ruby", spec_sha256: "Ry6N90Xp7Or9qGoWziaaTotD1K7vOAonnRAAPjXCzic=")
      Maintenance::BackfillSpecSha256Task.process(v)

      assert_equal "Ry6N90Xp7Or9qGoWziaaTotD1K7vOAonnRAAPjXCzic=", v.reload.spec_sha256
    end

    should "error if spec_sha256 is incorrect" do
      RubygemFs.instance.store("quick/Marshal.4.8/rubygem-1.gemspec.rz", "spec contents 2")

      v = create(:version, rubygem: @rubygem, number: "1", platform: "ruby", spec_sha256: "Ry6N90Xp7Or9qGoWziaaTotD1K7vOAonnRAAPjXCzic=")
      assert_no_changes "v.reload.spec_sha256" do
        e = assert_raise(RuntimeError) { Maintenance::BackfillSpecSha256Task.process(v) }

        assert_includes e.message, "Version rubygem-1 has incorrect spec_sha256"
      end
    end
  end
end
