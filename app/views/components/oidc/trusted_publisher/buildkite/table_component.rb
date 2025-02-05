class OIDC::TrustedPublisher::Buildkite::TableComponent < ApplicationComponent
  prop :buildkite, reader: :public

  def view_template
    dl(class: "tw-flex tw-flex-col sm:tw-grid sm:tw-grid-cols-2 tw-items-baseline tw-gap-4 full-width overflow-wrap") do
      dt(class: "description__heading ") { "Organization Slug" }
      dd { code { buildkite.organization_slug } }

      dt(class: "description__heading ") { "Pipeline Slug" }
      dd { code { buildkite.pipeline_slug } }
    end
  end
end
