class OIDC::TrustedPublisher::GitLab::TableComponent < ApplicationComponent
  prop :gitlab, reader: :public

  def view_template
    dl(class: "tw-flex tw-flex-col sm:tw-grid sm:tw-grid-cols-2 tw-items-baseline tw-gap-4 full-width overflow-wrap") do
      dt(class: "description__heading ") { "GitLab Project Path" }
      dd { code { gitlab.project_path } }

      dt(class: "description__heading ") { "GitLab Ref Path" }
      dd { code { gitlab.ref_path } }

      if gitlab.environment.present?
        dt(class: "description__heading ") { "GitLab Environment" }
        dd { code { gitlab.environment } }
      end

      if gitlab.ci_config_ref_uri.present?
        dt(class: "description__heading ") { "GitLab CI Config Ref URI" }
        dd { code { gitlab.ci_config_ref_uri } }
      end
    end
  end
end
