# frozen_string_literal: true

FactoryBot.define do
  factory :maintenance_tasks_run, class: "MaintenanceTasks::Run" do
    task_name { Maintenance::UserTotpSeedEmptyToNilTask.name }
  end
end
