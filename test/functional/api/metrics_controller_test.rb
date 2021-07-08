require "test_helper"

class Api::MetricsControllerTest < ActionController::TestCase
  setup do
    StatsD.stubs(:increment)
    @id = "ad4373ca1c57c905"
    @metrics =
      [
        {
          "command" => "list",
          "timestamp" => "2019-08-28T09:46:02Z",
          "command_time_taken" => "0.00189",
          "options" => "jobs,without,build.mysql"
        },
        {
          "time_to_download" => "0.297",
          "time_to_resolve_gemfile" => "1.96",
          "command" => "outdated",
          "timestamp" => "2019-08-28T09:46:18Z",
          "command_time_taken" => "2.049",
          "options" => "jobs,without,build.mysql"
        },
        {
          "request_id" => "ad4373ca1c57c905",
          "origin" => "2c1ff14a7ac6b6b150e1f2aaf25f87ea",
          "git_version" => "2.20.1",
          "rbenv_version" => "1.1.2-2-g4e92322",
          "rvm_version" => "1.1.0",
          "chruby_version" => "1.0",
          "host" => "x86_64-pc-linux-gnu",
          "ruby_version" => "2.6.2",
          "bundler_version" => "2.1.0.pre.1",
          "rubygems_version" => "3.0.3",
          "gemfile_gem_count" => 4,
          "installed_gem_count" => 42,
          "git_gem_count" => 0,
          "path_gem_count" => 0,
          "gem_source_count" => 1,
          "gem_sources" => ["63ce7be7e747a374ed4f503489c9f8b2"],
          "ci" => "jenkins,travis"
        }
      ]
    @garbage_metrics =
      [
        {
          "time_to_download" => "0.297",
          "time_to_resolve_gemfile" => "1.96",
          "command" => "????????????????????",
          "timestamp" => "2019-08-28T09:46:18Z",
          "command_time_taken" => "2.049",
          "options" => "this is a very long option,this is a another very long option"
        },
        {
          "request_id" => "d0d733adace7e1a8",
          "origin" => "2c1ff14a7ac6b6b150e1f2aaf25f87ea",
          "git_version" => "4a7na6ubab",
          "rbenv_version" => "laim734nai734nia73",
          "rvm_version" => "22222222222",
          "chruby_version" => "515151..",
          "host" => "aaaaaaaaveryyyyyyyylonggggghosttttttt",
          "ruby_version" => "iaw3l7n7a34",
          "bundler_version" => ",iue4n",
          "rubygems_version" => "aa",
          "gemfile_gem_count" => 4,
          "installed_gem_count" => 42,
          "git_gem_count" => 0,
          "path_gem_count" => 0,
          "gem_source_count" => 1,
          "gem_sources" => ["63ce7be7e747a374ed4f503489c9f8b2"],
          "ci" => "this is a very long ci,this is a another very long ci"
        }
      ]
  end

  context "reporting metrics once" do
    should "increment the right values" do
      StatsD.expects(:increment) { |metric| metric.with("command.outdated") }
      StatsD.expects(:increment) { |metric| metric.with("host.x86_64-pc-linux-gnu") }
      StatsD.expects(:increment) { |metric| metric.with("ruby_version.2.6.2") }
      StatsD.expects(:increment) { |metric| metric.with("bundler_version.2.1.0.pre.1") }
      StatsD.expects(:increment) { |metric| metric.with("rubygems_version.3.0.3") }
      StatsD.expects(:increment) { |metric| metric.with("git_version.2.20.1") }
      StatsD.expects(:increment) { |metric| metric.with("rvm_version.1.1.0") }
      StatsD.expects(:increment) { |metric| metric.with("rbenv_version.1.1.2-2-g4e92322") }
      StatsD.expects(:increment) { |metric| metric.with("chruby_version.1.0") }
      StatsD.expects(:increment) { |metric| metric.with("options.jobs") }
      StatsD.expects(:increment) { |metric| metric.with("options.without") }
      StatsD.expects(:increment) { |metric| metric.with("option.build.mysql") }
      StatsD.expects(:increment) { |metric| metric.with("ci.jenkins") }
      StatsD.expects(:increment) { |metric| metric.with("ci.travis") }
      post :create, body: @metrics.to_yaml, as: :yaml
    end
  end

  context "taking several hashes" do
    should "increment the correct command key for two different commands" do
      StatsD.expects(:increment) { |metric| metric.with("command.list") }
      StatsD.expects(:increment) { |metric| metric.with("command.outdated") }
      post :create, body: @metrics.to_yaml, as: :yaml
    end
  end

  context "input is garbage" do
    should "ignore garbage values and not increment for them" do
      StatsD.expects(:increment) { |metric| metric.with("bundler_version.ae4wt4et") }.never
      StatsD.expects(:increment) { |metric| metric.with("rubygems_version.ae44aswe6") }.never
      StatsD.expects(:increment) { |metric| metric.with("ruby_version.68df68fd86") }.never
      StatsD.expects(:increment) { |metric| metric.with("command.???????????????????") }.never
      StatsD.expects(:increment) { |metric| metric.with("host.aaaaaavvvvveryyyyylongggghostttttttttt") }.never
      StatsD.expects(:increment) { |metric| metric.with("git_version.5f67mdr7msr7s") }.never
      StatsD.expects(:increment) { |metric| metric.with("rbenv_version.wz3so;8rnzw73rgiznb") }.never
      StatsD.expects(:increment) { |metric| metric.with("rvm_version.2222222222") }.never
      StatsD.expects(:increment) { |metric| metric.with("chruby_version.515151...") }.never
      StatsD.expects(:increment) { |metric| metric.with("options.this is a very long option") }.never
      StatsD.expects(:increment) { |metric| metric.with("options.this is another very long option") }.never
      StatsD.expects(:increment) { |metric| metric.with("ci.and this is a very long ci") }.never
      StatsD.expects(:increment) { |metric| metric.with("ci.and this is another very long ci") }.never
      post :create, body: @garbage_metrics.to_yaml, as: :yaml
    end
  end

  context "when the metrics array doesn't exist" do
    should "do nothing and not crash" do
      expects(:validate_data).never
      expects(:split_increment).never
      post :create, body: nil, as: :yaml
    end
  end

  context "reporting metrics second time" do
    setup do
      Rails.cache.stubs(:read).with(@id).returns(true)
    end

    should "not increment the metrics again" do
      StatsD.expects(:increment) { |metric| metric.with("bundler_version.2.1.0.pre.1") }.never
      StatsD.expects(:increment) { |metric| metric.with("chruby_version.1.0") }.never
      post :create, body: @metrics.to_yaml, as: :yaml
    end
  end
end
