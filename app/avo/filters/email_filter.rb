class EmailFilter < Avo::Filters::TextFilter
  self.name = "Email filter"
  self.button_label = "Filter by email"

  def apply(_request, query, value)
    query.where(query.arel_table[email_column].matches_regexp(value, false))
  end

  private

  def email_column
    arguments.fetch(:column, :email)
  end
end
