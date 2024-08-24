# frozen_string_literal: true

module Maintenance
  # Helper to keep backfilling LogTickets to TimescaleDB downloads table.
  # It will be used to migrate the data from the old LogTicket table to the new LogDownload table.
  # It will be executed in the background and it will be a one time task.
  # Later, after all pending LogTickets are migrated, this job will be removed.
  class BackfillLogTicketsToTimescaleDownloadsTask < MaintenanceTasks::Task
    def collection
      LogDownload.where(status: "pending")
    end

    def process(element)
      FastlyLogDownloadsProcessor.new(element.directory, element.key).perform
    end
  end
end
