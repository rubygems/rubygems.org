namespace :swiftype do
  task :index_rubygems => :environment do
    ENV['SWIFTYPE_ENGINE_SLUG'] = "rubygems"

    if ENV['SWIFTYPE_API_KEY'].blank?
      abort("SWIFTYPE_API_KEY not set")
    end

    if ENV['SWIFTYPE_ENGINE_SLUG'].blank?
      abort("SWIFTYPE_ENGINE_SLUG not set")
    end

    client = Swiftype::Client.new

    Rubygem.find_in_batches(:batch_size => 100) do |rubygems|
      documents = rubygems.map{ |rubygem| rubygem.to_st_hash }

      results = client.create_or_update_documents_verbose(ENV['SWIFTYPE_ENGINE_SLUG'], Rubygem.model_name.downcase, documents)

      results.each_with_index do |result, index|
        puts "Could not create #{rubygems[index].title} (##{rubygems[index].id})" if result == false
      end
    end
  end
end
