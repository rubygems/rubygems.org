require File.dirname(__FILE__) + '/../test_helper'

class WebHookJobTest < ActiveSupport::TestCase

  context "given a hook and a gem" do

    setup do
      @hook    = Factory(:web_hook)
      @version = Factory(:version, 
                         :number            => "3.2.1", 
                         :rubyforge_project => "foogem-rf",
                         :authors           => "AUTHORS",
                         :description       => "DESC",
                         :summary           => "SUMMARY")
      @rubygem = Factory(:rubygem,
                         :name      => "foogem",
                         :versions  => [ @version ],
                         :downloads => 42)
      @version.rubygem = @rubygem
      @version.save
      @job  = WebHookJob.new(@hook, @rubygem, 'localhost:1234')
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
      assert_equal "http://localhost:1234/gems/foogem", payload['project_uri']
      assert_equal "http://localhost:1234/gems/foogem-3.2.1.gem", payload['gem_uri']
    end

  end

  context "with valid URL" do
    setup do 
      @url = 'http://example.com/gemcutter'
      @hook = Factory(:web_hook, :url => @url)
      @rubygem  = Factory(:rubygem, :versions => [Factory(:version)])
      @job  = WebHookJob.new(@hook, @rubygem, 'example.org')
      WebMock.stub_request(:post, @url)
      @job.perform
    end

    should "POST to URL with payload" do
      # Three assertions are used to more easily determine where failure occurs
      WebMock.assert_requested(:post, @url, 
                               :times => 1)
      WebMock.assert_requested(:post, @url, 
                               :body => @job.payload)
      WebMock.assert_requested(:post, @url, 
                               :headers => { 'Content-Type' => 'application/json' })
    end

    should "not increment failure count for hook" do
      assert_equal 0, @job.hook.failure_count
    end

  end

  context "with invalid URL" do
    setup do
      @url     = 'http://someinvaliddomain.com'
			@user    = Factory(:email_confirmed_user)
      @rubygem = Factory(:rubygem, :versions => [Factory(:version)])
      @hook    = Factory(:web_hook, :url     => @url,
															      :rubygem => @rubygem,
                                    :user    => @user)
      @job  = WebHookJob.new(@hook, @rubygem, 'example.org')
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
        WebMock.stub_request(:post, @url).to_raise(exception)
        @job.perform
        assert_equal index+1, @job.hook.failure_count
      end
    end
  end
end
