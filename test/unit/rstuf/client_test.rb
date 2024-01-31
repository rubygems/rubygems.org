require "test_helper"

class Rstuf::ClientTest < ActiveSupport::TestCase
  setup do
    setup_rstuf
  end

  test "post_artifacts should post targets and return task_id on success" do
    task_id = "12345"
    stub_request(:post, "#{Rstuf.base_url}/api/v1/artifacts/")
      .with(body: { targets: %w[artifact1 artifact2] })
      .to_return(body: { data: { task_id: task_id } }.to_json, status: 200, headers: { "Content-Type" => "application/json" })

    response_task_id = Rstuf::Client.post_artifacts(%w[artifact1 artifact2])

    assert_equal task_id, response_task_id
  end

  test "post_artifacts should raise Error on failure" do
    error_message = "Invalid targets"
    stub_request(:post, "#{Rstuf.base_url}/api/v1/artifacts/")
      .with(body: { targets: %w[artifact1 artifact2] })
      .to_return(body: { error: error_message }.to_json, status: 400, headers: { "Content-Type" => "application/json" })

    assert_raises(Rstuf::Client::Error) do
      Rstuf::Client.post_artifacts(%w[artifact1 artifact2])
    end
  end

  test "delete_artifacts should post targets for deletion and return task_id on success" do
    task_id = "67890"
    stub_request(:post, "#{Rstuf.base_url}/api/v1/artifacts/delete")
      .with(body: { targets: %w[artifact1 artifact2] })
      .to_return(body: { data: { task_id: task_id } }.to_json, status: 200, headers: { "Content-Type" => "application/json" })

    response_task_id = Rstuf::Client.delete_artifacts(%w[artifact1 artifact2])

    assert_equal task_id, response_task_id
  end

  test "delete_artifacts should raise Error on failure" do
    error_message = "Could not delete"
    stub_request(:post, "#{Rstuf.base_url}/api/v1/artifacts/delete")
      .with(body: { targets: %w[artifact1 artifact2] })
      .to_return(body: { error: error_message }.to_json, status: 400, headers: { "Content-Type" => "application/json" })

    assert_raises(Rstuf::Client::Error) do
      Rstuf::Client.delete_artifacts(%w[artifact1 artifact2])
    end
  end

  test "task_state should return the status of the task" do
    task_id = "12345"
    state = "processing"
    stub_request(:get, "#{Rstuf.base_url}/api/v1/task/")
      .with(query: { task_id: task_id })
      .to_return(body: { data: { state: state } }.to_json, status: 200, headers: { "Content-Type" => "application/json" })

    status = Rstuf::Client.task_state(task_id)

    assert_equal state, status
  end

  test "task_state should raise Error if task retrieval fails" do
    task_id = "12345"
    error_message = "Task not found"
    stub_request(:get, "#{Rstuf.base_url}/api/v1/task/")
      .with(query: { task_id: task_id })
      .to_return(body: { error: error_message }.to_json, status: 404, headers: { "Content-Type" => "application/json" })

    assert_raises(Rstuf::Client::Error) do
      Rstuf::Client.task_state(task_id)
    end
  end

  teardown do
    teardown_rstuf
  end
end
