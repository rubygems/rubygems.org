require "elasticsearch/rails/tasks/import"

namespace :elasticsearch do
  task :drop do
    Rubygem.__elasticsearch__.client.indices.delete index: Rubygem.index_name
  end
  task :create do
    Rubygem.__elasticsearch__.create_index! force: true
    Rubygem.__elasticsearch__.refresh_index!
  end

  task :import_alias do
    old_idx = Rubygem.__elasticsearch__.client.cat.aliases(name: Rubygem.index_name, h: ["index"]).strip
    new_idx = "#{Rubygem.index_name}-#{Time.zone.now.strftime('%Y%m%d%H%M')}"

    res = Rubygem.__elasticsearch__.client.count index: old_idx
    puts "Count before import: #{res['count']}"

    Rubygem.import index: new_idx, force: true

    res = Rubygem.__elasticsearch__.client.count index: new_idx
    puts "Count after import: #{res['count']}"

    Rubygem.__elasticsearch__.client.indices.update_aliases body: {
      actions: [
        { remove: { index: old_idx, alias: Rubygem.index_name } },
        { add: { index: new_idx, alias: Rubygem.index_name } }
      ]
    }
    Rubygem.__elasticsearch__.delete_index! index: old_idx
  end
end
