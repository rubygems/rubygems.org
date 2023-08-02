module MaintenanceTasksAuditable
  extend ActiveSupport::Concern

  prepended do
    include Auditable
    around_action :audit_action, except: %i[index show]

    def audit_action(&)
      action = params.fetch(:action)
      task_name = params.fetch(:task_id)

      action_name = "Manual #{action} of #{task_name}"

      run = @run

      value, _audit = in_audited_transaction(
        auditable: run || ->(changed_records:) { changed_records.keys.grep(MaintenanceTasks::Run).sole },
        admin_github_user: admin_user,
        action: action_name,
        fields: params.slice(:comment).reverse_merge(comment: action_name),
        arguments: params,
        models: [run].compact,
        &
      )
      value
    end
  end
end
