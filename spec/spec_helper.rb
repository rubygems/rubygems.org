$:.unshift File.join(File.dirname(__FILE__), '..')

require 'rubygems'
require 'spec'
require 'gemcutter'
require 'sinatra/test/rspec'
require 'rr'
require 'webrat'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end

# Ripped from actionpack.
require 'tempfile'
class TestUploadedFile
  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The content type of the "uploaded" file
  attr_accessor :content_type

  def initialize(path, content_type = Mime::TEXT, binary = false)
    raise "#{path} file does not exist" unless File.exist?(path)
    @content_type = content_type
    @original_filename = path.sub(/^.*#{File::SEPARATOR}([^#{File::SEPARATOR}]+)$/) { $1 }
    @tempfile = Tempfile.new(@original_filename)
    @tempfile.set_encoding(Encoding::BINARY) if @tempfile.respond_to?(:set_encoding)
    @tempfile.binmode if binary
    FileUtils.copy_file(path, @tempfile.path)
  end

  def path #:nodoc:
    @tempfile.path
  end

  alias local_path path

  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.__send__(method_name, *args, &block)
  end
end
