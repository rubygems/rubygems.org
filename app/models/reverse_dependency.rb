class ReverseDependency
  def initialize(rubygem_id)
    @rubygem_id = rubygem_id

    @distinct_rubygems_query = <<-SQL
    SELECT  DISTINCT ON (r.id) r.id, r.name, r.created_at, r.updated_at, r.slug, gd.count FROM rubygems as r
      INNER JOIN gem_downloads as gd ON gd.rubygem_id = r.id AND gd.version_id = 0
      INNER JOIN versions AS v ON v.rubygem_id = r.id
      INNER JOIN dependencies AS d ON d.version_id = v.id
      WHERE (v.indexed = 't' AND v.position = 0 AND d.rubygem_id = :rubygem_id)
    SQL
  end

  def by_downloads(offset, limit)
    Rubygem.find_by_sql(
      ["SELECT rubygems.* FROM (#{@distinct_rubygems_query}) AS rubygems ORDER BY count DESC OFFSET :offset LIMIT :limit",
       rubygem_id: @rubygem_id,
       offset: offset,
       limit: limit]
    )
  end

  def search(query, offset, limit)
    search_distinct_query = <<-SQL
    SELECT rubygems.* FROM (#{@distinct_rubygems_query}) AS rubygems
      WHERE (UPPER(rubygems.name) LIKE UPPER(:query) OR
            UPPER(TRANSLATE(rubygems.name,
                      '#{Patterns::SPECIAL_CHARACTERS}',
                      '#{' ' * Patterns::SPECIAL_CHARACTERS.length}')
            ) LIKE UPPER(:query))
      ORDER BY count DESC OFFSET :offset LIMIT :limit
    SQL

    Rubygem.find_by_sql(
      [search_distinct_query,
       query: "%#{query.strip}%",
       rubygem_id: @rubygem_id,
       offset: offset,
       limit: limit]
    )
  end

  # legacy method to find reverse depdencies. is used only in api
  # returns duplicate rubygem records. multiplatform gems have multiple versions with position = 0
  def legacy_find
    Rubygem.joins("inner join versions as v on v.rubygem_id = rubygems.id
      inner join dependencies as d on d.version_id = v.id").where("v.indexed = 't'
      and v.position = 0 and d.rubygem_id = ?", @rubygem_id)
  end

  def development
    legacy_find.where("d.scope = 'development'")
  end

  def runtime
    legacy_find.where("d.scope ='runtime'")
  end
end
