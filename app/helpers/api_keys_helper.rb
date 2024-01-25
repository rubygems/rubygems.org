module ApiKeysHelper
  def gem_scope(api_key)
    return invalid_gem_tooltip(api_key.soft_deleted_rubygem_name) if api_key.soft_deleted_by_ownership?

    api_key.rubygem ? api_key.rubygem.name : t("api_keys.all_gems")
  end

  def api_key_scope_html_data(api_scope)
    if ApiKey::EXCLUSIVE_SCOPES.include?(api_scope)
      {
        api_key_form_target: "exclusiveCheckbox"
      }
    else
      {
        api_key_form_target: "checkbox",
        gemscope: ApiKey::APPLICABLE_GEM_API_SCOPES.include?(api_scope) ? api_scope : nil
      }
    end
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
