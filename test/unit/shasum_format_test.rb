# frozen_string_literal: true

require "test_helper"

class ShasumFormatTest < ActiveSupport::TestCase
  FILE = <<~SHASUM
    3e8179ae8e3354a22ad6c9f08a81ac2e7e39cf7b65c7dd97895cb23bf22cd48c  MIT-LICENSE
    70bf070e16ea64e6b9f4d90ec5dd3380a645b4bcdcfe2121b44f14faa97ed8ce  README.rdoc
    c7805b18b735aadab8889fd34bceef1d308b4dc63ffd976422342dbac3404d70  exe/rake
    8e43d75374cfcac83933176c32adb3a01d6488aa34c05bf91f6fe8dfe48c52a5  lib/rake.rb
  SHASUM

  CHECKSUMS = {
    "MIT-LICENSE" => "3e8179ae8e3354a22ad6c9f08a81ac2e7e39cf7b65c7dd97895cb23bf22cd48c",
    "README.rdoc" => "70bf070e16ea64e6b9f4d90ec5dd3380a645b4bcdcfe2121b44f14faa97ed8ce",
    "exe/rake" => "c7805b18b735aadab8889fd34bceef1d308b4dc63ffd976422342dbac3404d70",
    "lib/rake.rb" => "8e43d75374cfcac83933176c32adb3a01d6488aa34c05bf91f6fe8dfe48c52a5"
  }.freeze

  context ".generate" do
    should "generate a shasum file" do
      assert_equal FILE, ShasumFormat.generate(CHECKSUMS)
    end

    should "generate an empty file" do
      assert_equal "", ShasumFormat.generate({})
    end

    should "tolerate bad input" do
      assert_equal "", ShasumFormat.generate({ "foo" => nil, "" => "bar" })
    end
  end

  context ".parse" do
    should "parse a shasum file we generated" do
      assert_equal CHECKSUMS, ShasumFormat.parse(FILE)
    end

    should "parse an empty file to an empty hash" do
      assert_empty ShasumFormat.parse("")
      assert_empty ShasumFormat.parse("").values
    end

    should "raise ParseError on malformed file" do
      assert_raises(ShasumFormat::ParseError) do
        ShasumFormat.parse("boom")
      end
    end
  end
end
