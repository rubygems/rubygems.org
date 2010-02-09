if defined? Delayed::Job
  require File.expand_path(File.join(File.dirname(__FILE__),'/../test_helper'))
  
  class LongRunningJob
    def perform
      sleep 5
    end
  end
  
  class NamedJob
    def display_name
      'some custom name'
    end
    def perform
      true
    end
  end
  
  class DelayedJobTest < Test::Unit::TestCase
    def local_env
      NewRelic::Control.instance.local_env
    end
    
    def worker_name
      local_env.dispatcher_instance_id
    end
    
    def lock_n_jobs(n=1)
      n.times do
        job = Delayed::Job.create
        job.update_attributes({
          :locked_at => Time.now,
          :locked_by => worker_name
        })
      end
    end
    
    def setup      
      NewRelic::Agent.manual_start
      @agent = NewRelic::Agent.instance
      
      @agent.transaction_sampler.harvest
      @agent.stats_engine.clear_stats
    end

    def teardown
      @agent.instance_variable_set("@histogram", NewRelic::Histogram.new)
    end
    
    def test_job_instrumentation
      job = Delayed::Job.new(:payload_object => LongRunningJob.new)
      job_name = "Controller/Task/Delayed::Job/LongRunningJob"
            
      job.invoke_job
      job_stats = @agent.stats_engine.get_stats(job_name)
      
      assert @agent.stats_engine.metrics.include?(job_name)
      assert_equal 1, job_stats.call_count
    end
    
    def test_custom_name
      job = Delayed::Job.new(:payload_object => NamedJob.new)
      job_name = "Controller/Task/Delayed::Job/some custom name"
            
      job.invoke_job
      job_stats = @agent.stats_engine.get_stats(job_name)
      
      assert @agent.stats_engine.metrics.include?(job_name)
      assert_equal 1, job_stats.call_count
    end
    
    def test_lock_sampler
      stats_engine = NewRelic::Agent::StatsEngine.new
      sampler = NewRelic::Agent::Samplers::DelayedJobLockSampler.new
      sampler.stats_engine = stats_engine
            
      lock_n_jobs(1)
      sampler.poll
      
      assert_equal 1, sampler.stats.data_point_count
      assert_equal 1, sampler.stats.min_call_time
      assert_equal 1, sampler.stats.max_call_time
      
      lock_n_jobs(4)
      sampler.poll
      
      assert_equal 2, sampler.stats.data_point_count
      assert_equal 1, sampler.stats.min_call_time
      assert_equal 5, sampler.stats.max_call_time
      
      lock_n_jobs(5)
      sampler.poll
      sampler.poll
      
      assert_equal 4, sampler.stats.data_point_count
      assert_equal 1, sampler.stats.min_call_time
      assert_equal 10, sampler.stats.max_call_time
      
      Delayed::Job.destroy_all
      sampler.poll
      
      assert_equal 5, sampler.stats.data_point_count
      assert_equal 0, sampler.stats.min_call_time
      assert_equal 10, sampler.stats.max_call_time
    end
    
  end
end
