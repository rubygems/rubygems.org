require 'elasticsearch/rails/tasks/import'

namespace :elasticsearch do
  task :drop do
    Rubygem.__elasticsearch__.client.indices.delete index: Rubygem.index_name
  end
  task :create do
    Rubygem.__elasticsearch__.create_index! force: true
    Rubygem.__elasticsearch__.refresh_index!
  end
end
