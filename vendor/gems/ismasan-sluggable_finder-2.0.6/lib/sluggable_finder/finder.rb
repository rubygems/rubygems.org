module SluggableFinder
  # This module is included by the base class as well as AR asociation collections
  #
  module Finder
    def find_sluggable(opts,*args)
      key = args.first
      if (key.is_a?(String) and !(key =~ /\A\d+\Z/))#only contain digits
          options = {:conditions => ["#{ opts[:to]} = ?", key]}
          error = "There is no #{opts[:sluggable_type]} with #{opts[:to]} '#{key}'"
          with_scope(:find => options) do
            find_without_slug(:first) or 
            raise SluggableFinder.not_found_exception.new(error)
          end
      else
        find_without_slug(*args)
      end
    end
  end
  
  module BaseFinder
    
    def find_with_slug(*args)
      return find_without_slug(*args) unless respond_to?(:sluggable_finder_options)
      options = sluggable_finder_options
      find_sluggable(options,*args)
    end
  end
  
  module AssociationProxyFinder
    def find_with_slug(*args)
      return find_without_slug(*args) unless @reflection.klass.respond_to?(:sluggable_finder_options)
      options = @reflection.klass.sluggable_finder_options
      find_sluggable(options,*args)
    end
  end
  
end