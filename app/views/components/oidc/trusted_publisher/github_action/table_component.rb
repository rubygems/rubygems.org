# frozen_string_literal: true

class OIDC::TrustedPublisher::GitHubAction::TableComponent < ApplicationComponent
  prop :github_action, reader: :public

  def view_template
    dl(class: "mt-4 grid grid-cols-1 gap-x-8 gap-y-3 sm:grid-cols-2") do
      detail_row("GitHub Repository", github_action.repository)
      detail_row("Workflow Filename", github_action.workflow_filename)
      detail_row("Workflow Repository", github_action.workflow_repository) if github_action.workflow_repository_owner.present?
      detail_row("Environment", github_action.environment) if github_action.environment?
    end
  end

  private

  def detail_row(label, value)
    div do
      dt(class: "text-b4 font-semibold text-neutral-800 dark:text-neutral-200") { label }
      dd(class: "mt-0.5 break-all") do
        code(class: "font-mono text-c4 text-neutral-900 dark:text-white") { value }
      end
    end
  end
end
