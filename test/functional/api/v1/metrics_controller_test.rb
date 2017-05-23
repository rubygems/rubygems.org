require 'test_helper'

class Api::V1::MetricsControllerTest < ActionController::TestCase
  setup do
    StatsD.stubs(:increment)
    @id = "9d16bd9809d392ca"
    @metric = { bundler:  "1.10.4.beta.1",
                rubygems: "2.4.1",
                ruby:     "2.1.2",
                arch:     "x86_64-apple-darwin13.2.0",
                command:  "update",
                options:  "jobs,without,build.mysql",
                ci:       "jenkins,ci",
                id:        @id }
  end

  context "reporting metrics first time" do
    should "increment the right values" do
      StatsD.expects(:increment) { |metric| metric.with("bundler.1.10.4.beta.1") }
      StatsD.expects(:increment) { |metric| metric.with("rubygems.2.4.1") }
      StatsD.expects(:increment) { |metric| metric.with("ruby.2.1.2") }
      StatsD.expects(:increment) { |metric| metric.with("command.update") }
      StatsD.expects(:increment) { |metric| metric.with("arch.x86_64-apple-darwin13.2.0") }
      StatsD.expects(:increment) { |metric| metric.with("option.jobs") }
      StatsD.expects(:increment) { |metric| metric.with("option.without") }
      StatsD.expects(:increment) { |metric| metric.with("option.build.mysql") }
      StatsD.expects(:increment) { |metric| metric.with("ci.jenkins") }
      StatsD.expects(:increment) { |metric| metric.with("ci.ci") }
      post :create, params: @metric
    end
  end

  context "reporting metrics second time" do
    setup do
      Rails.cache.stubs(:read).with(@id).returns(true)
    end

    should "not increment metric" do
      StatsD.expects(:increment) { |metric| metric.with("bundler.1.10.4.beta.1") }.never
      post :create, params: @metric
    end
  end
end
