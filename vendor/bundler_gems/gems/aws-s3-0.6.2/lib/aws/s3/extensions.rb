#:stopdoc:

class Hash
  def to_query_string(include_question_mark = true)
    query_string = ''
    unless empty?
      query_string << '?' if include_question_mark
      query_string << inject([]) do |params, (key, value)| 
        params << "#{key}=#{value}" 
      end.join('&')
    end
    query_string
  end
  
  def to_normalized_options
    # Convert all option names to downcased strings, and replace underscores with hyphens
    inject({}) do |normalized_options, (name, value)|
      normalized_options[name.to_header] = value.to_s
      normalized_options
    end
  end
  
  def to_normalized_options!
    replace(to_normalized_options)
  end
end

class String
  if RUBY_VERSION <= '1.9'
    def previous!
      self[-1] -= 1
      self
    end
  else
    def previous!
      self[-1] = (self[-1].ord - 1).chr
      self
    end
  end
  
  def previous
    dup.previous!
  end
  
  def to_header
    downcase.tr('_', '-')
  end
  
  # ActiveSupport adds an underscore method to String so let's just use that one if
  # we find that the method is already defined
  def underscore
    gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").downcase
  end unless public_method_defined? :underscore

  if RUBY_VERSION >= '1.9'
    def valid_utf8?
      dup.force_encoding('UTF-8').valid_encoding?
    end
  else
    def valid_utf8?
      scan(Regexp.new('[^\x00-\xa0]', nil, 'u')) { |s| s.unpack('U') }
      true
    rescue ArgumentError
      false
    end
  end
  
  # All paths in in S3 have to be valid unicode so this takes care of 
  # cleaning up any strings that aren't valid utf-8 according to String#valid_utf8?
  if RUBY_VERSION >= '1.9'
    def remove_extended!
      sanitized_string = ''
      each_byte do |byte|
        character = byte.chr
        sanitized_string << character if character.ascii_only?
      end
      sanitized_string
    end
  else
    def remove_extended!
      gsub!(/[\x80-\xFF]/) { "%02X" % $&[0] }
    end
  end
  
  def remove_extended
    dup.remove_extended!
  end
end

class CoercibleString < String
  class << self
    def coerce(string)
      new(string).coerce
    end
  end
  
  def coerce
    case self
    when 'true';         true
    when 'false';         false
    # Don't coerce numbers that start with zero
    when  /^[1-9]+\d*$/;   Integer(self)
    when datetime_format; Time.parse(self)
    else
      self
    end
  end
  
  private
    # Lame hack since Date._parse is so accepting. S3 dates are of the form: '2006-10-29T23:14:47.000Z'
    # so unless the string looks like that, don't even try, otherwise it might convert an object's
    # key from something like '03 1-2-3-Apple-Tree.mp3' to Sat Feb 03 00:00:00 CST 2001.
    def datetime_format
      /^\d{4}-\d{2}-\d{2}\w\d{2}:\d{2}:\d{2}/
    end
end

class Symbol
  def to_header
    to_s.to_header
  end
end

module Kernel
  def __method__(depth = 0)
    caller[depth][/`([^']+)'/, 1]
  end if RUBY_VERSION <= '1.8.7'
  
  def __called_from__
    caller[1][/`([^']+)'/, 1]
  end if RUBY_VERSION > '1.8.7'
  
  def expirable_memoize(reload = false, storage = nil)
    current_method = RUBY_VERSION > '1.8.7' ? __called_from__ : __method__(1)
    storage = "@#{storage || current_method}"
    if reload 
      instance_variable_set(storage, nil)
    else
      if cache = instance_variable_get(storage)
        return cache
      end
    end
    instance_variable_set(storage, yield)
  end

  def require_library_or_gem(library, gem_name = nil)
    if RUBY_VERSION >= '1.9'
      gem(gem_name || library, '>=0') 
    end
    require library
  rescue LoadError => library_not_installed
    begin
      require 'rubygems'
      require library
    rescue LoadError
      raise library_not_installed
    end
  end
end

class Object
  def returning(value)
    yield(value)
    value
  end
end

class Module
  def memoized(method_name)
    original_method = "unmemoized_#{method_name}_#{Time.now.to_i}"
    alias_method original_method, method_name
    module_eval(<<-EVAL, __FILE__, __LINE__)
      def #{method_name}(reload = false, *args, &block)
        expirable_memoize(reload) do
          send(:#{original_method}, *args, &block)
        end
      end
    EVAL
  end
  
  def constant(name, value)
    unless const_defined?(name)
      const_set(name, value) 
      module_eval(<<-EVAL, __FILE__, __LINE__)
        def self.#{name.to_s.downcase}
          #{name.to_s}
        end
      EVAL
    end
  end
  
  # Transforms MarcelBucket into
  #
  #   class MarcelBucket < AWS::S3::Bucket
  #     set_current_bucket_to 'marcel'
  #   end
  def const_missing_from_s3_library(sym)
    if sym.to_s =~ /^(\w+)(Bucket|S3Object)$/
      const = const_set(sym, Class.new(AWS::S3.const_get($2)))
      const.current_bucket = $1.underscore
      const
    else
      const_missing_not_from_s3_library(sym)
    end
  end
  alias_method :const_missing_not_from_s3_library, :const_missing
  alias_method :const_missing, :const_missing_from_s3_library
end


class Class # :nodoc:
  def cattr_reader(*syms)
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}
          @@#{sym}
        end

        def #{sym}
          @@#{sym}
        end
      EOS
    end
  end

  def cattr_writer(*syms)
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end

        def #{sym}=(obj)
          @@#{sym} = obj
        end
      EOS
    end
  end

  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end
end if Class.instance_methods(false).grep(/^cattr_(?:reader|writer|accessor)$/).empty?

module SelectiveAttributeProxy
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.class_eval(<<-EVAL, __FILE__, __LINE__)
      cattr_accessor :attribute_proxy
      cattr_accessor :attribute_proxy_options
      
      # Default name for attribute storage
      self.attribute_proxy         = :attributes
      self.attribute_proxy_options = {:exclusively => true}
      
      private
        # By default proxy all attributes
        def proxiable_attribute?(name)
          return true unless self.class.attribute_proxy_options[:exclusively]
          send(self.class.attribute_proxy).has_key?(name)
        end
        
        def method_missing(method, *args, &block)
          # Autovivify attribute storage
          if method == self.class.attribute_proxy
            ivar = "@\#{method}"
            instance_variable_set(ivar, {}) unless instance_variable_get(ivar).is_a?(Hash)
            instance_variable_get(ivar)
          # Delegate to attribute storage
          elsif method.to_s =~ /^(\\w+)(=?)$/ && proxiable_attribute?($1)
            attributes_hash_name = self.class.attribute_proxy
            $2.empty? ? send(attributes_hash_name)[$1] : send(attributes_hash_name)[$1] = args.first
          else
            super
          end
        end
    EVAL
  end
  
  module ClassMethods
    def proxy_to(attribute_name, options = {})
      if attribute_name.is_a?(Hash)
        options = attribute_name
      else
        self.attribute_proxy = attribute_name
      end
      self.attribute_proxy_options = options
    end
  end
end

# When streaming data up, Net::HTTPGenericRequest hard codes a chunk size of 1k. For large files this
# is an unfortunately low chunk size, so here we make it use a much larger default size and move it into a method
# so that the implementation of send_request_with_body_stream doesn't need to be changed to change the chunk size (at least not anymore
# than I've already had to...).
module Net
  class HTTPGenericRequest
    def send_request_with_body_stream(sock, ver, path, f)
      raise ArgumentError, "Content-Length not given and Transfer-Encoding is not `chunked'" unless content_length() or chunked?
      unless content_type()
        warn 'net/http: warning: Content-Type did not set; using application/x-www-form-urlencoded' if $VERBOSE
        set_content_type 'application/x-www-form-urlencoded'
      end
      write_header sock, ver, path
      if chunked?
        while s = f.read(chunk_size)
          sock.write(sprintf("%x\r\n", s.length) << s << "\r\n")
        end
        sock.write "0\r\n\r\n"
      else
        while s = f.read(chunk_size)
          sock.write s
        end
      end
    end
    
    def chunk_size
      1048576 # 1 megabyte
    end
  end
  
  # Net::HTTP before 1.8.4 doesn't have the use_ssl? method or the Delete request type
  class HTTP
    def use_ssl?
      @use_ssl
    end unless public_method_defined? :use_ssl?
    
    class Delete < HTTPRequest
      METHOD = 'DELETE'
      REQUEST_HAS_BODY = false
      RESPONSE_HAS_BODY = true
    end unless const_defined? :Delete
  end
end

class XmlGenerator < String #:nodoc:
  attr_reader :xml
  def initialize
    @xml = Builder::XmlMarkup.new(:indent => 2, :target => self)
    super()
    build
  end
end
#:startdoc:
