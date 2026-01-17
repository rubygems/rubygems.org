class OIDC::TrustedPublisher::GitLab::TableComponent < ApplicationComponent
  prop :gitlab, reader: :public

  def view_template
    dl(class: "tw-flex tw-flex-col sm:tw-grid sm:tw-grid-cols-2 tw-items-baseline tw-gap-4 full-width overflow-wrap") do
      dt(class: "description__heading ") { "GitLab Project Path" }
      dd { code { gitlab.project_path } }

      dt(class: "description__heading ") { "GitLab CI Config Path" }
      dd { code { gitlab.ci_config_path } }

      if gitlab.environment.present?
        dt(class: "description__heading ") { "GitLab Environment" }
        dd { code { gitlab.environment } }
      end

      if gitlab.ref_type.present?
        dt(class: "description__heading ") { "Ref Type" }
        dd { code { gitlab.ref_type } }
      end

      if gitlab.branch_name.present?
        dt(class: "description__heading ") { "Branch Name" }
        dd { code { gitlab.branch_name } }
      end
    end
  end
end
