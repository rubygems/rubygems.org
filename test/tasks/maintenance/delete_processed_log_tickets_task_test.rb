# frozen_string_literal: true

require "test_helper"

class Maintenance::DeleteProcessedLogTicketsTaskTest < ActiveSupport::TestCase
  setup do
    @cutoff = Maintenance::DeleteProcessedLogTicketsTask::CUTOFF
    @task = Maintenance::DeleteProcessedLogTicketsTask.new
    @task.batch_size = 2
  end

  test "deletes only processed tickets created before the cutoff" do
    old_processed = create(:log_ticket, status: :processed, created_at: @cutoff - 1.year)
    old_pending = create(:log_ticket, status: :pending, created_at: @cutoff - 1.day)
    old_processing = create(:log_ticket, status: :processing, created_at: @cutoff - 1.day)
    old_failed = create(:log_ticket, status: :failed, created_at: @cutoff - 1.day)
    # Its id is below the last pre-cutoff id, so only the created_at check keeps it.
    at_cutoff = create(:log_ticket, status: :processed, created_at: @cutoff)
    last_old_processed = create(:log_ticket, status: :processed, created_at: @cutoff - 1.second)
    after_cutoff = create(:log_ticket, status: :processed, created_at: @cutoff + 1.day)

    assert_equal (old_processed.id..last_old_processed.id).to_a, @task.collection.each_record.map(&:id)
    assert_equal 3, @task.count

    @task.collection.each { |batch| @task.process(batch) }

    assert_equal [old_pending, old_processing, old_failed, at_cutoff, after_cutoff].map(&:id).sort, LogTicket.ids.sort
  end

  test "does nothing when no ticket predates the cutoff" do
    ticket = create(:log_ticket, status: :processed, created_at: @cutoff)

    assert_empty @task.collection.each_record.to_a
    assert_equal 0, @task.count

    @task.collection.each { |batch| @task.process(batch) }

    assert LogTicket.exists?(ticket.id)
  end
end
