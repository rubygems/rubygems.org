module ApiKeysHelper
  def gem_scope(api_key)
    return if api_key.soft_deleted?

    api_key.rubygem ? api_key.rubygem.name : t("api_keys.all_gems")
  end
end
