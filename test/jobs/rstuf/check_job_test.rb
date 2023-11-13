require "test_helper"

class Rstuf::CheckJobTest < ActiveJob::TestCase
  setup do
    setup_rstuf

    @task_id = "task123"
  end

  test "perform does not raise on success" do
    success_response = { "data" => { "state" => "SUCCESS" } }
    stub_request(:get, "#{Rstuf.base_url}/api/v1/task/?task_id=#{@task_id}")
      .to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })

    assert_nothing_raised do
      Rstuf::CheckJob.perform_now(@task_id)
    end
  end

  test "perform raises an error on failure" do
    failure_response = { "data" => { "state" => "FAILURE" } }
    stub_request(:get, "#{Rstuf.base_url}/api/v1/task/?task_id=#{@task_id}")
      .to_return(status: 200, body: failure_response.to_json, headers: { "Content-Type" => "application/json" })

    assert_raises(Rstuf::CheckJob::FailureException) do
      Rstuf::CheckJob.new.perform(@task_id)
    end
  end

  test "perform raises a retry exception on pending state and retries" do
    retry_response = { "data" => { "state" => "PENDING" } }
    stub_request(:get, "#{Rstuf.base_url}/api/v1/task/?task_id=#{@task_id}")
      .to_return(status: 200, body: retry_response.to_json, headers: { "Content-Type" => "application/json" })

    assert_enqueued_with(job: Rstuf::CheckJob, args: [@task_id]) do
      Rstuf::CheckJob.perform_now(@task_id)
    end
  end

  test "perform raises a retry exception on retry state and retries" do
    retry_response = { "data" => { "state" => "UNKNOWN" } }
    stub_request(:get, "#{Rstuf.base_url}/api/v1/task/?task_id=#{@task_id}")
      .to_return(status: 200, body: retry_response.to_json, headers: { "Content-Type" => "application/json" })

    assert_enqueued_with(job: Rstuf::CheckJob, args: [@task_id]) do
      Rstuf::CheckJob.perform_now(@task_id)
    end
  end

  teardown do
    teardown_rstuf
  end
end
