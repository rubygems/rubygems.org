$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module SluggableFinder
  VERSION = '2.0.6'
  
  @@not_found_exception = nil
  
  def self.not_found_exception=(ex)
    @@not_found_exception = ex
  end
  
  def self.not_found_exception
    @@not_found_exception || ActiveRecord::RecordNotFound
  end
  
  class << self
    
    def enable_activerecord
      ActiveRecord::Base.extend SluggableFinder::Orm::ClassMethods
      # support for associations
      a = ActiveRecord::Associations
      returning([ a::AssociationCollection ]) { |classes|
        # detect http://dev.rubyonrails.org/changeset/9230
        unless a::HasManyThroughAssociation.superclass == a::HasManyAssociation
          classes << a::HasManyThroughAssociation
        end
      }.each do |klass|
        klass.send :include, SluggableFinder::Finder
        klass.send :include, SluggableFinder::AssociationProxyFinder
        klass.alias_method_chain :find, :slug
      end
      
    end
    
  end
  
  def self.encode(str)
    if defined?(ActiveSupport::Inflector.parameterize)
      ActiveSupport::Inflector.parameterize(str).to_s
    else
      ActiveSupport::Multibyte::Handlers::UTF8Handler.
      		normalize(str,:d).split(//u).reject { |e| e.length > 1 }.join.strip.gsub(/[^a-z0-9]+/i, '-').downcase
    end
  end
  
  def self.random_slug_for(klass)
    Digest::SHA1.hexdigest( klass.name.to_s + Time.now.to_s )
  end
  
end

require 'rubygems'
require 'active_record'
require 'digest/sha1'

Dir.glob(File.dirname(__FILE__)+'/sluggable_finder/*.rb').each do |file|
  require file
end

SluggableFinder.enable_activerecord if (defined?(ActiveRecord) && !ActiveRecord::Base.respond_to?(:sluggable_finder))
