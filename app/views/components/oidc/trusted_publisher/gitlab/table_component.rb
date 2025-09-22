class OIDC::TrustedPublisher::GitLab::TableComponent < ApplicationComponent
  prop :gitlab, reader: :public

  def view_template
    dl(class: "tw-flex tw-flex-col sm:tw-grid sm:tw-grid-cols-2 tw-items-baseline tw-gap-4 full-width overflow-wrap") do
      dt(class: "description__heading ") { "GitLab Namespace Path" }
      dd { code { gitlab.namespace_path } }

      dt(class: "description__heading ") { "GitLab Project Path" }
      dd { code { gitlab.project_path } }
    end
  end
end
