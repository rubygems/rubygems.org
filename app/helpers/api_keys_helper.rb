module ApiKeysHelper
  def gem_scope(api_key)
    return invalid_gem_tooltip if api_key.soft_deleted_by_ownership?

    api_key.rubygem ? api_key.rubygem.name : t("api_keys.all_gems")
  end

  private

  def invalid_gem_tooltip
    content_tag(
      :span,
      "[?]",
      class: "tooltip__text",
      style: "font-size:1em",
      data: { tooltip: t("api_keys.gem_ownership_removed") }
    )
  end
end
