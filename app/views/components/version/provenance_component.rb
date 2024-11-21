# frozen_string_literal: true

class Version::ProvenanceComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  prop :attestation

  def view_template
    display_data = @attestation.display_data

    div(class: "gem__attestation") do
      div(class: "gem__attestation__built_on") do
        div(class: "gem__attestation__grid gem__attestation__grid__left") do
          p
          p { plain "Built and signed on" }
          p { "✅" }
          p { display_data[:ci_platform] }
          p
          p { link_to "Build summary", display_data[:build_summary_url], target: "_blank", rel: "noopener" }
        end
      end
      div(class: "gem__attestation__grid gem__attestation__grid__right") do
        p { plain "Source Commit" }
        p { link_to display_data[:source_commit_string], display_data[:source_commit_url] }
        p { plain "Build File" }
        p { link_to display_data[:build_file_string], display_data[:build_file_url] }
        p { plain "Public Ledger" }
        p { link_to "Transparency log entry", "https://search.sigstore.dev/?logIndex=#{display_data[:log_index]}" }
      end
    end
  end
end
