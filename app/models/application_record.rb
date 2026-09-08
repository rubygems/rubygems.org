# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include SemanticLogger::Loggable

  self.abstract_class = true

  def self.advisory_xact_lock!(name, id)
    raise ArgumentError, "advisory_xact_lock! requires an open transaction" unless connection.transaction_open?

    connection.select_value(
      sanitize_sql_array(["SELECT pg_advisory_xact_lock(hashtext(?), ?)", name.to_s, id])
    )
  end
end
