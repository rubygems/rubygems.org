#
# Create a PostgreSQL functional index on all Gem's names with - and _ charcters removed.
# This index is used by GemTypo to rapidly check newly uploaded Gems for matches against
# other Gems that are variations of another already published Gem simply by the variation in
# - and _ characters.
#

class AddDashUnderscoreTypoDetectionIndexToRubygems < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    execute "DROP INDEX IF EXISTS dashunderscore_typos_idx;"
    execute "CREATE INDEX CONCURRENTLY dashunderscore_typos_idx ON rubygems (regexp_replace(upper(name), '[_-]', '', 'g'));"
  end

  def down
    execute "DROP INDEX IF EXISTS dashunderscore_typos_idx;"
  end
end
