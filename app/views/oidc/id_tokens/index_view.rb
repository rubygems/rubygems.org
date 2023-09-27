# frozen_string_literal: true

class OIDC::IdTokens::IndexView < ApplicationView
  attr_reader :id_tokens

  def initialize(id_tokens:)
    @id_tokens = id_tokens
    super()
  end

  def template
    self.title = t(".title")

    div(class: "t-body") do
      header(class: "gems__header push--s") do
        p(class: "gems__meter l-mb-0") { plain helpers.page_entries_info(id_tokens) }
      end
      if id_tokens.present?
        render OIDC::IdToken::TableComponent.new(id_tokens:)
        plain helpers.paginate(id_tokens)
      end
    end
  end
end
