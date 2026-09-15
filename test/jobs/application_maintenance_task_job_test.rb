# frozen_string_literal: true

require "test_helper"

class ApplicationMaintenanceTaskJobTest < ActiveSupport::TestCase
  test "runs on the maintenance queue" do
    assert_equal "maintenance", ApplicationMaintenanceTaskJob.new.queue_name
  end

  test "MaintenanceTasks.job points at this class" do
    assert_equal "ApplicationMaintenanceTaskJob", MaintenanceTasks.job
  end
end
