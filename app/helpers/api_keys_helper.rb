module ApiKeysHelper
  def gem_scope(api_key)
    return invalid_gem_tooltip(api_key.soft_deleted_rubygem_name) if api_key.soft_deleted_by_ownership?

    api_key.rubygem ? api_key.rubygem.name : t("api_keys.all_gems")
  end

  def api_key_checkbox(form, api_scope)
    exclusive = ApiKey::EXCLUSIVE_SCOPES.include?(api_scope)
    gem_scope = ApiKey::APPLICABLE_GEM_API_SCOPES.include?(api_scope)

    data = {}
    data[:exclusive_checkbox_target] = exclusive ? "exclusive" : "inclusive"
    data[:gem_scope_target] = "checkbox" if gem_scope

    html_options = { class: "form__checkbox__input", id: api_scope, data: }
    form.check_box api_scope, html_options, "true", "false"
  end

  private

  def invalid_gem_tooltip(name)
    content_tag(
      :span,
      "#{name} [?]",
      class: "tooltip__text",
      data: { tooltip: t("api_keys.gem_ownership_removed", rubygem_name: name) }
    )
  end
end
