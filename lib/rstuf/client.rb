class Rstuf::Client
  include SemanticLogger::Loggable

  Error = Class.new(StandardError)

  def self.post_artifacts(targets)
    response = connection.post("/api/v1/artifacts/", { artifacts: targets })

    return response.body.dig("data", "task_id") if response.success?
    raise Error, "Error posting artifacts: #{response.body}"
  end

  def self.delete_artifacts(targets)
    response = connection.post("/api/v1/artifacts/delete", { artifacts: targets }, {})

    return response.body.dig("data", "task_id") if response.success?
    raise Error, "Error deleting artifacts: #{response.body}"
  end

  def self.task_state(task_id)
    result = get_task(task_id)
    result.dig("data", "state")
  end

  def self.connection
    Faraday.new(url: Rstuf.base_url) do |f|
      f.request :json
      f.response :json
      f.response :logger, logger
    end
  end

  def self.get_task(task_id)
    response = connection.get("/api/v1/task/", task_id: task_id)

    return response.body if response.success?
    raise Error, "Error fetching task: #{response.body}"
  end
end
