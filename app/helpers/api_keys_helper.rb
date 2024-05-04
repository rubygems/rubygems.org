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

  def self.api_key_params(params, existing_api_key = nil)
    scopes = params.fetch(:scopes, existing_api_key&.scopes || []).to_set
    boolean = ActiveRecord::Type::Boolean.new
    ApiKey::API_SCOPES.each do |scope|
      next unless params.key?(scope)

      if boolean.cast(params.delete(scope))
        scopes << scope
      else
        scopes.delete(scope)
      end
    end
    params[:scopes] = scopes.sort
    params
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
