require 'elasticsearch/rails/tasks/import'

namespace :elasticsearch do
  task :drop do
    Rubygem.__elasticsearch__.client.indices.delete index: Rubygem.index_name
  end
  task :create do
    Rubygem.__elasticsearch__.create_index! force: true
    Rubygem.__elasticsearch__.refresh_index!
  end

  task :import_alias do
    idx = Rubygem.__elasticsearch__.index_name
    res = Rubygem.__elasticsearch__.client.count index: idx
    puts "Count before import: #{res['count']}"

    new_idx = "#{idx}-#{Time.zone.today.strftime('%Y%m%d')}"
    Rubygem.import index: new_idx, force: true
    res = Rubygem.__elasticsearch__.client.count index: new_idx
    puts "Count after import: #{res['count']}"

    Rubygem.__elasticsearch__.delete_index! index: idx
    Rubygem.__elasticsearch__.client.indices.update_aliases body: {
      actions: [
        { add: { index: new_idx, alias: idx } }
      ]
    }
  end
end
