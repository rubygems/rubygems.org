require File.dirname(__FILE__) + '/../test_helper'

class WebHookJobTest < ActiveSupport::TestCase

  context "given a hook and a gem" do

    setup do
      @hook = Factory(:web_hook)
      @gem  = Factory(:rubygem,
                      :name      => "foogem",
                      :versions  => [
                                     Factory(:version, 
                                             :number               => "3.2.1", 
                                             :rubyforge_project    => "foogem-rf",
                                             :authors              => "AUTHORS",
                                             :description          => "DESC",
                                             :summary              => "SUMMARY")
                                    ],
                      :downloads => 42)
      
      @job  = WebHookJob.new(@hook, @gem)
    end

    should "have a hook" do
      assert_equal @hook, @job.hook
    end

    should "have gem properties encoded in JSON" do
      payload = ActiveSupport::JSON.decode(@job.payload)
      assert_equal "foogem",     payload['name']
      assert_equal "3.2.1",      payload['version']
      assert_equal "foogem-rf",  payload["rubyforge_project"]
      assert_equal "DESC",       payload["description"]
      assert_equal "SUMMARY",    payload["summary"]
      assert_equal "AUTHORS",    payload["authors"]
      assert_equal 42,           payload["downloads"]
    end

  end

  context "with valid URL" do

    setup do 
      @web_hook_url = 'http://example.com/gemcutter'
      @hook = Factory(:web_hook, :url => @web_hook_url)
      @gem  = Factory(:rubygem, :versions => [Factory(:version)])
      @job  = WebHookJob.new(@hook, @gem)
      WebMock.stub_request(:post, @web_hook_url)
      @job.perform
    end

    should "POST to URL with payload" do
      # Three assertions are used to more easily determine where failure occurs
      WebMock.assert_requested(:post, @web_hook_url, 
                               :times => 1)
      WebMock.assert_requested(:post, @web_hook_url, 
                               :body => @job.payload)
      WebMock.assert_requested(:post, @web_hook_url, 
                               :headers => { 'Content-Type' => 'application/json' })
    end

    should "not increment failure count for hook" do
      assert_equal 0, @job.hook.failure_count
    end

  end

  context "with invalid URL" do

    setup do
      @web_hook_url = 'http://someinvaliddomain.com'
      @hook = Factory(:web_hook, :url => @web_hook_url)
      @gem  = Factory(:rubygem, :versions => [Factory(:version)])
      @job  = WebHookJob.new(@hook, @gem)
    end
    
    should "increment failure count for hook on errors" do
      [SocketError,
       Timeout::Error,
       Errno::EINVAL,
       Errno::ECONNRESET,
       EOFError,
       Net::HTTPBadResponse,
       Net::HTTPHeaderSyntaxError,
       Net::ProtocolError].each_with_index do |exception, index|
        WebMock.stub_request(:post, @web_hook_url).to_raise(exception)
        @job.perform
        assert_equal index+1, @job.hook.failure_count
      end
    end

  end

end
