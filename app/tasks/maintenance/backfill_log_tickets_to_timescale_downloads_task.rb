# frozen_string_literal: true

module Maintenance
  class BackfillLogTicketsToTimescaleDownloadsTask < MaintenanceTasks::Task
    def collection
      LogDownload.where(status: "pending")
    end

    def process(element)
      FastlyLogDownloadsProcessor.new(element.directory, element.key).perform
    end
  end
end
