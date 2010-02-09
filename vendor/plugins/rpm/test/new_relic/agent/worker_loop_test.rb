require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper')) 

NewRelic::Agent::WorkerLoop.class_eval do 
  public :run_next_task
end

class NewRelic::Agent::WorkerLoopTest < Test::Unit::TestCase
  def setup
    @log = ""
    @logger = Logger.new(StringIO.new(@log))
    @worker_loop = NewRelic::Agent::WorkerLoop.new(@logger)
    @test_start_time = Time.now
  end
  def test_add_task
    @x = false
    period = 1.0
    @worker_loop.add_task(period) do
      @x = true
    end
    
    assert !@x
    @worker_loop.run_next_task
    assert @x
    check_test_timestamp period
  end
  
  def test_add_tasks_with_different_periods
    @last_executed = nil
    
    period1 = 0.5
    period2 = 0.7
    
    @worker_loop.add_task(period1) do
      @last_executed = 1
    end
    
    @worker_loop.add_task(period2) do
      @last_executed = 2
    end
    
    @worker_loop.run_next_task
    assert_equal @last_executed, 1
    check_test_timestamp(0.5)
    
    @worker_loop.run_next_task
    assert_equal @last_executed, 2
    check_test_timestamp(0.7)
    
    @worker_loop.run_next_task
    assert_equal @last_executed, 1 
    check_test_timestamp(1.0)
    
    @worker_loop.run_next_task
    assert_equal @last_executed, 2
    check_test_timestamp(1.4)
    
    @worker_loop.run_next_task
    assert_equal @last_executed, 1
    check_test_timestamp(1.5)
  end
  
  def test_task_error__standard
    @worker_loop.add_task(0.2) do
      raise "Standard Error Test"
    end
    # Should not throw
    @logger.expects(:error).once
    @logger.expects(:debug).never
    @worker_loop.run_next_task
    
  end
  def test_task_error__runtime
    @worker_loop.add_task(0.2) do
      raise RuntimeError, "Runtime Error Test"
    end
    # Should not throw, but log at error level
    # because it detects no agent listener inthe
    # stack
    @logger.expects(:error).once
    @logger.expects(:debug).never
    @worker_loop.run_next_task
  end

  def test_task_error__server
    @worker_loop.add_task(0.2) do
      raise NewRelic::Agent::ServerError, "Runtime Error Test"
    end
    # Should not throw
    @logger.expects(:error).never
    @logger.expects(:debug).once
    @worker_loop.run_next_task
  end
  
  private
  # The test is expected to have lasted no less than expected
  # and no more than expected + 100 ms.
  def check_test_timestamp(expected)
    ts = Time.now - @test_start_time
    delta = ts - expected
    assert(delta <= 0.250, "#{ts} duration includes a delay of #{delta} that exceeds 250 milliseconds")
  end
end
