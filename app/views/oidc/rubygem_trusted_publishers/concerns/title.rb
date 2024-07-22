module OIDC::RubygemTrustedPublishers::Concerns::Title
  extend ActiveSupport::Concern

  included do
    def title_content
      self.title_for_header_only = t(".title")
      content_for :title do
        h1(class: "t-display page__heading page__heading-small") do
          plain t(".title")

          i(class: "page__subheading page__subheading--block") do
            t(".subtitle_owner_html", gem_html: helpers.link_to(rubygem.name, rubygem_path(rubygem.slug), class: "t-link t-underline"))
          end
        end
      end
    end
  end
end
