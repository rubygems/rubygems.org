class OIDC::TrustedPublisher::GitHubAction::TableComponent < ApplicationComponent
  prop :github_action, reader: :public

  def view_template
    dl(class: "tw-flex tw-flex-col sm:tw-grid sm:tw-grid-cols-2 tw-items-baseline tw-gap-4 full-width overflow-wrap") do
      dt(class: "description__heading ") { "GitHub Repository" }
      dd { code { github_action.repository } }

      dt(class: "description__heading ") { "Workflow Filename" }
      dd { code { github_action.workflow_filename } }

      if github_action.environment?
        dt(class: "description__heading") { "Environment" }
        dd { code { github_action.environment } }
      end
    end
  end
end
