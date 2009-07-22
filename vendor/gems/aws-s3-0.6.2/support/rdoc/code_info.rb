require 'rubygems'
require 'rake'
require 'rdoc/rdoc'

module RDoc
  class CodeInfo    
    class << self
      def parse(wildcard_pattern = nil)
        @info_for_corpus = parse_files(wildcard_pattern)
      end
      
      def for(constant)
        new(constant).info
      end
      
      def info_for_corpus
        raise RuntimeError, "You must first generate a corpus to search by using RDoc::CodeInfo.parse" unless @info_for_corpus
        @info_for_corpus
      end
      
      def parsed_files
        info_for_corpus.map {|info| info.file_absolute_name}
      end
      
      def files_to_parse
        @files_to_parse ||= Rake::FileList.new
      end
      
      private
        def parse_files(pattern)
          files   = pattern ? Rake::FileList[pattern] : files_to_parse
          options = Options.instance
          options.parse(files << '-q', RDoc::GENERATORS)
          rdoc.send(:parse_files, options)
        end
        
        def rdoc
          TopLevel.reset
          rdoc  = RDoc.new
          stats = Stats.new
          # We don't want any output so we'll override the print method
          stats.instance_eval { def print; nil end } 
          rdoc.instance_variable_set(:@stats, stats)
          rdoc
        end
    end
    
    attr_reader :info
    def initialize(location)
      @location = CodeLocation.new(location)
      find_constant
      find_method if @location.has_method?
    end
    
    private
      attr_reader :location
      attr_writer :info
      def find_constant
        parts = location.namespace_parts
        self.class.info_for_corpus.each do |file_info|
          @info = parts.inject(file_info) do |result, const_part|
            (result.find_module_named(const_part) || result.find_class_named(const_part)) || break
          end
          return if info
        end
      end
      
      def find_method
        return unless info
        self.info = info.method_list.detect do |method_info|
          next unless method_info.name == location.method_name
          if location.class_method?
            method_info.singleton
          elsif location.instance_method?
            !method_info.singleton
          else
            true
          end
        end
      end
  end
  
  class CodeLocation
    attr_reader :location

    def initialize(location)
      @location = location
    end

    def parts
      location.split(/::|\.|#/)
    end

    def namespace_parts
      has_method? ? parts[0...-1] : parts
    end

    def has_method?
      ('a'..'z').include?(parts.last[0, 1])
    end

    def instance_method?
      !location['#'].nil?
    end

    def class_method?
      has_method? && !location[/#|\./]
    end

    def method_name
      parts.last if has_method?
    end
  end
end

if __FILE__ == $0
  require 'test/unit'
  class CodeInfoTest < Test::Unit::TestCase
    def setup
      RDoc::CodeInfo.parse(__FILE__)
    end
    
    def test_constant_lookup
      assert RDoc::CodeInfo.for('RDoc')
      
      info = RDoc::CodeInfo.for('RDoc::CodeInfo')
      assert_equal 'CodeInfo', info.name      
    end
    
    def test_method_lookup
      {'RDoc::CodeInfo.parse'          => true,
       'RDoc::CodeInfo::parse'         => true,
       'RDoc::CodeInfo#parse'          => false,
       'RDoc::CodeInfo.find_method'    => true,
       'RDoc::CodeInfo::find_method'   => false,
       'RDoc::CodeInfo#find_method'    => true,
       'RDoc::CodeInfo#no_such_method' => false,
       'RDoc::NoSuchConst#foo'         => false}.each do |location, result_of_lookup|
         assert_equal result_of_lookup, !RDoc::CodeInfo.for(location).nil?
       end
    end
  end
  
  class CodeLocationTest < Test::Unit::TestCase
    def test_parts
       {'Foo'           => %w(Foo),
        'Foo::Bar'      => %w(Foo Bar),
        'Foo::Bar#baz'  => %w(Foo Bar baz),
        'Foo::Bar.baz'  => %w(Foo Bar baz),
        'Foo::Bar::baz' => %w(Foo Bar baz),
        'Foo::Bar::Baz' => %w(Foo Bar Baz)}.each do |location, parts|
          assert_equal parts, RDoc::CodeLocation.new(location).parts
        end
    end
    
    def test_namespace_parts
      {'Foo'           => %w(Foo),
       'Foo::Bar'      => %w(Foo Bar),
       'Foo::Bar#baz'  => %w(Foo Bar),
       'Foo::Bar.baz'  => %w(Foo Bar),
       'Foo::Bar::baz' => %w(Foo Bar),
       'Foo::Bar::Baz' => %w(Foo Bar Baz)}.each do |location, namespace_parts|
         assert_equal namespace_parts, RDoc::CodeLocation.new(location).namespace_parts
       end
     end
    
    def test_has_method?
      {'Foo'           => false,
       'Foo::Bar'      => false,
       'Foo::Bar#baz'  => true,
       'Foo::Bar.baz'  => true,
       'Foo::Bar::baz' => true,
       'Foo::Bar::Baz' => false}.each do |location, has_method_result|
         assert_equal has_method_result, RDoc::CodeLocation.new(location).has_method?
       end
     end
     
    def test_instance_method?
      {'Foo'           => false,
       'Foo::Bar'      => false,
       'Foo::Bar#baz'  => true,
       'Foo::Bar.baz'  => false,
       'Foo::Bar::baz' => false,
       'Foo::Bar::Baz' => false}.each do |location, is_instance_method|
         assert_equal is_instance_method, RDoc::CodeLocation.new(location).instance_method?
       end
     end
     
     def test_class_method?
       {'Foo'           => false,
        'Foo::Bar'      => false,
        'Foo::Bar#baz'  => false,
        'Foo::Bar.baz'  => false,
        'Foo::Bar::baz' => true,
        'Foo::Bar::Baz' => false}.each do |location, is_class_method|
          assert_equal is_class_method, RDoc::CodeLocation.new(location).class_method?
        end
      end
      
      def test_method_name
        {'Foo'           => nil,
         'Foo::Bar'      => nil,
         'Foo::Bar#baz'  => 'baz',
         'Foo::Bar.baz'  => 'baz',
         'Foo::Bar::baz' => 'baz',
         'Foo::Bar::Baz' => nil}.each do |location, method_name|
           assert_equal method_name, RDoc::CodeLocation.new(location).method_name
         end
       end
  end
end