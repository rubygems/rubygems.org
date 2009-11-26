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
      assert_same @hook, @job.hook
    end

    should "have gem properties" do
      assert_equal "foogem",     @job.gem['name']
      assert_equal "3.2.1",      @job.gem['version']
      assert_equal "foogem-rf",  @job.gem["rubyforge_project"]
      assert_equal "DESC",       @job.gem["description"]
      assert_equal "SUMMARY",    @job.gem["summary"]
      assert_equal "AUTHORS",    @job.gem["authors"]
      assert_equal 42,           @job.gem["downloads"]
    end
  end
end
