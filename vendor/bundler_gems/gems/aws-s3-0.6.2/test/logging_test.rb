require File.dirname(__FILE__) + '/test_helper'

class LoggingStatusReadingTest < Test::Unit::TestCase
  
  def setup
    @disabled   = logging_status(:logging_disabled)
    @enabled    = logging_status(:logging_enabled)
    @new_status = Logging::Status.new('target_bucket' => 'foo', 'target_prefix' => 'access-log-')
  end
  
  def test_logging_enabled?
    assert !@disabled.logging_enabled?
    assert !@new_status.logging_enabled?
    assert @enabled.logging_enabled?
  end
  
  def test_passing_in_prefix_and_bucket
    assert_equal 'foo', @new_status.target_bucket
    assert_equal 'access-log-', @new_status.target_prefix
    assert !@new_status.logging_enabled?
  end
  
  private
    def logging_status(fixture)
      Logging::Status.new(Parsing::XmlParser.new(Fixtures::Logging[fixture.to_s]))
    end
end

class LoggingStatusWritingTest < LoggingStatusReadingTest
  def setup
    super
    @disabled = Logging::Status.new(Parsing::XmlParser.new(@disabled.to_xml))
    @enabled  = Logging::Status.new(Parsing::XmlParser.new(@enabled.to_xml))
  end
end

class LogTest < Test::Unit::TestCase
  def test_value_converted_to_log_lines
    log_object = S3Object.new
    log_object.value = Fixtures::Logs.simple_log.join
    log = Logging::Log.new(log_object)
    assert_nothing_raised do
      log.lines
    end
    
    assert_equal 2, log.lines.size
    assert_kind_of Logging::Log::Line, log.lines.first
    assert_equal 'marcel', log.lines.first.bucket
  end
end

class LogLineTest < Test::Unit::TestCase
  def setup
    @line = Logging::Log::Line.new(Fixtures::Loglines.bucket_get)
  end
  
  def test_field_accessors
    expected_results = {
      :owner            => Owner.new('id' => 'bb2041a25975c3d4ce9775fe9e93e5b77a6a9fad97dc7e00686191f3790b13f1'),
      :bucket           => 'marcel',
      :time             => Time.parse('Nov 14 2006 06:36:48 +0000'),
      :remote_ip        => '67.165.183.125',
      :request_id       => '8B5297D428A05432',
      :requestor        => Owner.new('id' => 'bb2041a25975c3d4ce9775fe9e93e5b77a6a9fad97dc7e00686191f3790b13f1'),
      :operation        => 'REST.GET.BUCKET',
      :key              => nil,
      :request_uri      => 'GET /marcel HTTP/1.1',
      :http_status      => 200,
      :error_code       => nil,
      :bytes_sent       => 4534,
      :object_size      => nil,
      :total_time       => 398,
      :turn_around_time => 395,
      :referrer         => nil,
      :user_agent       => nil
    }
     
     expected_results.each do |field, expected|
       assert_equal expected, @line.send(field)
     end
     
     assert_equal expected_results, @line.attributes
   end
   
  def test_user_agent
    line = Logging::Log::Line.new(Fixtures::Loglines.browser_get)
    assert_equal 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1) Gecko/20061010 Firefox/2.0', line.user_agent
  end
end