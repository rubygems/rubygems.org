require "test_helper"

class NotifyWebHookJobTest < ActiveJob::TestCase
  context "with a rubygem and version" do
    setup do
      @rubygem = create(:rubygem, name: "foogem", downloads: 42)
      @version = create(:version,
        rubygem: @rubygem,
        number: "3.2.1",
        authors: %w[AUTHORS],
        description: "DESC")
      @hook    = create(:web_hook, rubygem: @rubygem)
      @job     = NotifyWebHookJob.new(webhook: @hook, protocol: "http", host_with_port: "localhost:1234", version: @version)
    end

    should "have gem properties encoded in JSON" do
      payload = @job.run_callbacks(:perform) { JSON.parse(@job.payload) }

      assert_equal "foogem",    payload["name"]
      assert_equal "3.2.1",     payload["version"]
      assert_equal "ruby",      payload["platform"]
      assert_equal "DESC",      payload["info"]
      assert_equal "AUTHORS",   payload["authors"]
      assert_equal 42,          payload["downloads"]
      assert_equal "http://localhost:1234/gems/foogem", payload["project_uri"]
      assert_equal "http://localhost:1234/gems/foogem-3.2.1.gem", payload["gem_uri"]
    end

    should "send the right version out even for older gems" do
      new_version = create(:version, number: "2.0.0", rubygem: @rubygem)
      new_hook    = create(:web_hook)
      job         = NotifyWebHookJob.new(webhook: new_hook, protocol: "http", host_with_port: "localhost:1234", version: new_version)
      payload     = job.run_callbacks(:perform) { JSON.parse(job.payload) }

      assert_equal "foogem", payload["name"]
      assert_equal "2.0.0",  payload["version"]
      assert_equal "http://localhost:1234/gems/foogem", payload["project_uri"]
      assert_equal "http://localhost:1234/gems/foogem-2.0.0.gem", payload["gem_uri"]
    end
  end

  context "with an invalid URL" do
    setup do
      @hook = create(:web_hook)
      @job = NotifyWebHookJob.new(webhook: @hook, protocol: "http", host_with_port: "localhost:1234", version: create(:version))
    end

    should "discard the job on a 422 with hook relay" do
      NotifyWebHookJob.any_instance.expects(:use_hook_relay?).twice.returns(true)
      RestClient::Request.expects(:execute).with(has_entries(
                                                   method: :post,
                                                   url: "https://api.hookrelay.dev/hooks///webhook_id-#{@hook.id}",
                                                   headers: has_entries(
                                                     "Content-Type" => "application/json",
                                                     "HR_TARGET_URL" => @hook.url,
                                                     "HR_MAX_ATTEMPTS" => "3"
                                                   )
                                                 )).raises(
                                                   RestClient::UnprocessableEntity.new(RestClient::Response.new({ error: "Invalid url" }.to_json))
                                                 )

      perform_enqueued_jobs do
        @job.enqueue
      end

      assert_performed_jobs 1, only: NotifyWebHookJob
      assert_enqueued_jobs 0, only: NotifyWebHookJob
    end

    should "finish the job on a 422 without hook relay" do
      NotifyWebHookJob.any_instance.expects(:use_hook_relay?).once.returns(false)
      RestClient::Request.expects(:execute).with(has_entries(
                                                   method: :post,
                                                   url: @hook.url,
                                                   headers: has_entries(
                                                     "Content-Type" => "application/json",
                                                     "HR_TARGET_URL" => @hook.url,
                                                     "HR_MAX_ATTEMPTS" => "3"
                                                   )
                                                 )).raises RestClient::UnprocessableEntity.new

      perform_enqueued_jobs do
        @job.enqueue
      end

      assert_performed_jobs 1, only: NotifyWebHookJob
      assert_enqueued_jobs 0, only: NotifyWebHookJob
    end
  end
end
