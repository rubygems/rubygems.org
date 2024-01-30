# frozen_string_literal: true

require "test_helper"

class Gemcutter::UserAgentParserTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  test "parses a browser user agent" do
    assert_parse_as "Mozilla/5.0 (Linux; Android 10; SM-A205U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.101 Mobile Safari/537.36",
      { installer: "Browser", device: "Samsung SM-A205U", os: "Android", user_agent: "Chrome Mobile" }
  end

  test "parses a bundler user agent" do
    assert_parse_as \
      "bundler/1.12.5 rubygems/2.6.10 ruby/2.3.1 (x86_64-pc-linux-gnu) command/install options/orig_path 95ac718b0e500f41",
      { installer: "Bundler", implementation: "Ruby", system: "x86_64-pc-linux-gnu" }
    assert_parse_as \
      "bundler/1.12.5 rubygems/2.6.10 ruby/2.3.1 (x86_64-pc-linux-gnu) command/install jruby/9.2.4.0 options/orig_path 95ac718b0e500f41",
      { installer: "Bundler", implementation: "JRuby", system: "x86_64-pc-linux-gnu" }
    assert_parse_as \
      "bundler/1.12.5 rubygems/2.6.10 ruby/2.3.1 (x86_64-pc-linux-gnu) command/install truffleruby/23.1.2 options/orig_path 95ac718b0e500f41",
      { installer: "Bundler", implementation: "TruffleRuby", system: "x86_64-pc-linux-gnu" }
  end

  test "parses a rubygems user agent" do
    assert_parse_as "RubyGems/2.7.7 x86_64-linux Ruby/1.8.7 (2012-10-12 patchlevel 371)",
      { installer: "RubyGems", implementation: "Ruby", system: "x86_64-linux" }
    assert_parse_as "Ruby, RubyGems/2.7.7 x86_64-linux Ruby/2.6.0dev (2018-06-15 revision 63671)",
      { installer: "RubyGems", implementation: "Ruby", system: "x86_64-linux" }
    assert_parse_as "Ruby, Gems 1.1.1",
      { installer: "RubyGems", implementation: "Ruby" }
  end

  test "raises on an unknown user agent" do
    refute_parse "Unknown/1.0"
    refute_parse "Unknown"
  end

  def refute_parse(string)
    assert_raises Gemcutter::UserAgentParser::UnableToParse do
      Gemcutter::UserAgentParser.call(string)
    end
  end

  def assert_parse_as(string, hash)
    assert_equal Events::UserAgentInfo.new(**hash), Gemcutter::UserAgentParser.call(string, exclusive: true)
  end
end
