# frozen_string_literal: true

module Maintenance
  # This task is used to backfill log downloads from log tickets.
  # It is used to migrate from past to present using created_at date to order
  # limit 500 per iteration and use latest created_at date to get the next 500
  # later union with pending tickets.
  class BackfillLogDownloadsFromLogTicketsTask < MaintenanceTasks::Task
    def collection
      # migrate from past to present using created_at date to order
      # limit 500 per iteration and use latest created_at date to get the next 500
      # later union with pending tickets
      scope = LogTicket.processed.order(created_at: :asc)
      last_created_at = LogDownload.latest_created_at
      scope = scope.where("created_at < ?", last_created_at) if last_created_at
      scope
        .limit(500)
        .union(LogTicket.pending.order(created_at: :asc).limit(500))
    end

    def process(batch)
      LogDownload.insert_all(batch.select(:id, :status, :directory, :key, :created_at).to_a.map(&:attributes))
    end
  end
end
