# frozen_string_literal: true

require "test_helper"

class DeleteProcessedLogTicketsJobTest < ActiveJob::TestCase
  # The scheduled run on Nov 1 must keep everything created since Oct 1.
  RUN_AT = Time.utc(2026, 11, 1, 5, 0, 0)
  CUTOFF = Time.utc(2026, 10, 1)

  context "#perform" do
    setup { travel_to RUN_AT }

    should "delete processed tickets created before the start of the previous month and keep later ones" do
      # Created in id order, as in production.
      old = create(:log_ticket, status: :processed, created_at: CUTOFF - 1.second)
      at_cutoff = create(:log_ticket, status: :processed, created_at: CUTOFF)
      last_month = create(:log_ticket, status: :processed, created_at: Time.utc(2026, 10, 31, 23, 59, 59))
      this_month = create(:log_ticket, status: :processed, created_at: RUN_AT - 1.hour)

      DeleteProcessedLogTicketsJob.perform_now

      refute LogTicket.exists?(old.id)
      assert_equal [at_cutoff, last_month, this_month].map(&:id), LogTicket.order(:id).ids
    end

    should "keep pending, processing and failed tickets older than the cutoff" do
      processed = create(:log_ticket, status: :processed, created_at: Time.utc(2017, 1, 1))
      kept = %i[pending processing failed].map do |status|
        create(:log_ticket, status:, created_at: Time.utc(2017, 1, 1))
      end
      newest_old_processed = create(:log_ticket, status: :processed, created_at: CUTOFF - 1.day)

      DeleteProcessedLogTicketsJob.perform_now

      refute LogTicket.exists?(processed.id)
      refute LogTicket.exists?(newest_old_processed.id)
      assert_equal kept.map(&:id), LogTicket.order(:id).ids
    end
  end
end
