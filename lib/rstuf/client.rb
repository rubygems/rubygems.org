module Rstuf
  class Client
    Error = Class.new(StandardError)

    def self.post_artifacts(targets)
      response = connection.post("/api/v1/artifacts/", { targets: targets })

      return response.body.dig("data", "task_id") if response.success?
      raise Error, "Error posting artifacts: #{response.body}"
    end

    def self.delete_artifacts(targets)
      response = connection.post("/api/v1/artifacts/delete", { targets: targets }, {})

      return response.body.dig("data", "task_id") if response.success?
      raise Error, "Error deleting artifacts: #{response.body}"
    end

    def self.task_status(task_id)
      result = get_task(task_id)
      return result.dig("data", "state")
    end

    private

    def self.connection
      Faraday.new(url: Rstuf.base_url) do |f|
        f.request :json
        f.response :json
      end
    end

    def self.get_task(task_id)
      response = connection.get("/api/v1/task/", task_id: task_id)

      return response.body if response.success?
      raise Error, "Error fetching task: #{response.body}"
    end
  end
end
