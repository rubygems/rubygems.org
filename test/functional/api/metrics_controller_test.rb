require "test_helper"

class Api::MetricsControllerTest < ActionController::TestCase
  setup do
    StatsD.stubs(:increment)
    @id = "8b837d26ba400285"
    @metric = { bundler_version:  "2.1.0.pre.1",
                rubygems_version: "3.0.3",
                ruby_version:     "2.6.2",
                host:     "x86_64-pc-linux-gnu",
                command:  "install",
                git_version: "2.20.1",
                rbenv_version: "1.1.2-2-g4e92322",
                rvm_version: "1.1.0",
                chruby_version: "1.0",
                options:  "jobs,without,build.mysql",
                ci:       "jenkins,travis",
                request_id:    @id }
  end

  context "reporting metrics once" do
    should "increment the right values" do
      StatsD.expects(:increment) { |metric| metric.with("bundler_version.2.1.0.pre.1") }
      StatsD.expects(:increment) { |metric| metric.with("rubygems_version.3.0.3") }
      StatsD.expects(:increment) { |metric| metric.with("ruby_version.2.6.2") }
      StatsD.expects(:increment) { |metric| metric.with("host.x86_64-pc-linux-gnu") }
      StatsD.expects(:increment) { |metric| metric.with("command.install") }
      StatsD.expects(:increment) { |metric| metric.with("git_version.2.20.1") }
      StatsD.expects(:increment) { |metric| metric.with("rbenv_version.1.1.2-2-g4e92322") }
      StatsD.expects(:increment) { |metric| metric.with("rvm_version.1.1.0") }
      StatsD.expects(:increment) { |metric| metric.with("chruby_version.1.0") }
      StatsD.expects(:increment) { |metric| metric.with("options.jobs") }
      StatsD.expects(:increment) { |metric| metric.with("options.without") }
      StatsD.expects(:increment) { |metric| metric.with("option.build.mysql") }
      StatsD.expects(:increment) { |metric| metric.with("ci.jenkins") }
      StatsD.expects(:increment) { |metric| metric.with("ci.travis") }
      post :create, params: @metric
    end
  end

  context "reporting metrics second time" do
    setup do
      Rails.cache.stubs(:read).with(@id).returns(true)
    end

    should "not increment the metrics again" do
      StatsD.expects(:increment) { |metric| metric.with("bundler_version.2.1.0.pre.1") }.never
      post :create, params: @metric
    end
  end
end
