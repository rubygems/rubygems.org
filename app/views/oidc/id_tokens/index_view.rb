# frozen_string_literal: true

class OIDC::IdTokens::IndexView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :id_tokens

  def initialize(id_tokens:)
    @id_tokens = id_tokens
    super()
  end

  def view_template
    self.title = t(".title")

    subject_sidebar

    render CardComponent.new do |c|
      c.head { c.title(t(".title"), icon: "settings") }

      header(class: "flex items-center py-4") do
        p(class: HEADING) { plain page_entries_info(id_tokens) }
      end

      if id_tokens.present?
        render OIDC::IdToken::TableComponent.new(id_tokens:)
        plain paginate(id_tokens)
      end
    end
  end

  private

  HEADING = "text-sm text-neutral-600 dark:text-neutral-400 uppercase tracking-wide"

  def subject_sidebar
    content_for :subject do
      view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :profile })
    end
  end
end
