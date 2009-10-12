#:stopdoc:
module AWS
  module S3
    module Parsing
      class << self
        def parser=(parsing_library)
          XmlParser.parsing_library = parsing_library
        end
        
        def parser
          XmlParser.parsing_library
        end
      end
      
      module Typecasting
        def typecast(object)
          case object
          when Hash
            typecast_hash(object)
          when Array
            object.map {|element| typecast(element)}
          when String
            CoercibleString.coerce(object)
          else
            object
          end
        end
        
        def typecast_hash(hash)
          if content = hash['__content__']  
            typecast(content)
          else
            keys   = hash.keys.map {|key| key.underscore}
            values = hash.values.map {|value| typecast(value)}
            keys.inject({}) do |new_hash, key|
              new_hash[key] = values.slice!(0)
              new_hash
            end
          end
        end
      end
      
      class XmlParser < Hash
        include Typecasting
        
        class << self
          attr_accessor :parsing_library
        end
        
        attr_reader :body, :xml_in, :root
        
        def initialize(body)
          @body = body
          unless body.strip.empty?
            parse
            set_root
            typecast_xml_in
          end
        end
      
        private
      
          def parse
            @xml_in = self.class.parsing_library.xml_in(body, parsing_options)
          end
          
          def parsing_options
            {
              # Includes the enclosing tag as the top level key
              'keeproot'      => true, 
              # Makes tag value available via the '__content__' key
              'contentkey'    => '__content__', 
              # Always parse tags into a hash, even when there are no attributes 
              # (unless there is also no value, in which case it is nil)
              'forcecontent'  => true, 
              # If a tag is empty, makes its content nil
              'suppressempty' => nil,
              # Force nested elements to be put into an array, even if there is only one of them
              'forcearray'    => ['Contents', 'Bucket', 'Grant']
            }
          end
          
          def set_root
            @root = @xml_in.keys.first.underscore
          end
          
          def typecast_xml_in
            typecast_xml = {}
            @xml_in.dup.each do |key, value| # Some typecasting is destructive so we dup
              typecast_xml[key.underscore] = typecast(value)
            end
            # An empty body will try to update with a string so only update if the result is a hash
            update(typecast_xml[root]) if typecast_xml[root].is_a?(Hash)
          end
      end
    end
  end
end
#:startdoc: