# frozen_string_literal: true

class Search::FormComponent < ApplicationComponent
  include Phlex::Rails::Helpers::FormTag
  include Phlex::Rails::Helpers::SearchFieldTag
  include Phlex::Rails::Helpers::LabelTag
  include Phlex::Rails::Helpers::SubmitTag
  include Phlex::Rails::Helpers::LinkTo

  extend Dry::Initializer

  option :home
  option :query

  # this is dumb because we should just change this to a supported element
  register_element :center

  def template
    div role: "search", class: tokens(home?: "home__search-wrap", header?: "header__search-wrap") do
      form_tag search_path, method: :get, data: { controller: "autocomplete", autocomplete_selected_class: "selected" } do
        search_field

        suggestions

        label_tag :query, id: "querylabel" do
          span class: "t-hidden" do
            t("layouts.application.header.search_gem_html")
          end
        end

        submit_tag "⌕", id: "search_submit", name: nil, class: tokens(home?: "home__search__icon", header?: "header__search__icon"), aria: { labelledby: "querylabel" }

        if home?
          p class: "text-center" do
            link_to t("advanced_search"), advanced_search_path, class: "home__advanced__search t-link--has-arrow"
          end
        end
      end
    end
  end

  private

  def home? = home
  def header? = !home?

  def search_field_actions
    tokens(
      "autocomplete#suggest",
      "keydown.down->autocomplete#next",
      "keydown.up->autocomplete#prev",
      "keydown.esc->autocomplete#hide",
      "keydown.enter->autocomplete#clear",
      "click@window->autocomplete#hide",
      "focus->autocomplete#suggest",
      "blur->autocomplete#hide",
    )
  end

  def search_field
    data = {
      autocomplete_target: "query",
      action: search_field_actions
    }

    data[:nav_target] = "search" if header?

    search_field_tag(
      :query,
      query,
      placeholder: t("layouts.application.header.search_gem_html"),
      autofocus: home?,
      class: tokens(home?: "home__search", header?: "header__search"),
      autocomplete: "off",
      aria: { autocomplete: "list" },
      data: data
    )
  end

  def suggestions
    ul(class: "suggest-list", role: "listbox", data: { autocomplete_target: "suggestions" })

    template_tag(id: "suggestion", data_autocomplete_target: "template") do
      li(class: "menu-item", role: "option", tabindex: "-1", data: { autocomplete_target: "item", action: "click->autocomplete#choose mouseover->autocomplete#highlight" })
    end
  end
end
