require "test_helper"

class FastlyPurgeJobTest < ActiveJob::TestCase
  test "calls Fastly.purge with soft: true" do
    Fastly.expects(:purge).with({ path: "path", soft: true })
    FastlyPurgeJob.perform_now(path: "path", soft: true)
  end

  test "calls Fastly.purge with soft: false" do
    Fastly.expects(:purge).with({ path: "path", soft: false })
    FastlyPurgeJob.perform_now(path: "path", soft: false)
  end

  test "calls Fastly.purge_key" do
    Fastly.expects(:purge_key).with("key", soft: false)
    FastlyPurgeJob.perform_now(key: "key", soft: false)
  end
end
