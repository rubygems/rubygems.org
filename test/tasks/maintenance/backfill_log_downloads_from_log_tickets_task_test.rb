# frozen_string_literal: true

require "test_helper"

module Maintenance
  class BackfillLogDownloadsFromLogTicketsTaskTest < ActiveSupport::TestCase
    setup do
      # create a list of log ticket  statuses
      @log_ticket_statuses = %w[pending processed]
      @log_ticket_statuses.each do |status|
        3.times { create(:log_ticket, status: status) }
      end
    end

    test "#process performs a task iteration" do
      assert_equal LogTicket.count, 6
      assert_equal LogDownload.count, 0
      Maintenance::BackfillLogDownloadsFromLogTicketsTask.process(LogTicket.all)
      assert_equal LogDownload.count, 6
    end
  end
end
