require File.dirname(__FILE__) + '/database'

class SimpleJob
  cattr_accessor :runs; self.runs = 0
  def perform; @@runs += 1; end
end

class RandomRubyObject  
  def say_hello
    'hello'
  end
end

class ErrorObject

  def throw
    raise ActiveRecord::RecordNotFound, '...'
    false
  end

end

class StoryReader

  def read(story)
    "Epilog: #{story.tell}"
  end

end

class StoryReader

  def read(story)
    "Epilog: #{story.tell}"
  end

end

describe 'random ruby objects' do
  before       { Delayed::Job.delete_all }

  it "should respond_to :send_later method" do

    RandomRubyObject.new.respond_to?(:send_later)

  end

  it "should raise a ArgumentError if send_later is called but the target method doesn't exist" do
    lambda { RandomRubyObject.new.send_later(:method_that_deos_not_exist) }.should raise_error(NoMethodError)
  end

  it "should add a new entry to the job table when send_later is called on it" do
    Delayed::Job.count.should == 0

    RandomRubyObject.new.send_later(:to_s)

    Delayed::Job.count.should == 1
  end

  it "should add a new entry to the job table when send_later is called on the class" do
    Delayed::Job.count.should == 0

    RandomRubyObject.send_later(:to_s)

    Delayed::Job.count.should == 1
  end

  it "should run get the original method executed when the job is performed" do

    RandomRubyObject.new.send_later(:say_hello)

    Delayed::Job.count.should == 1
  end

  it "should ignore ActiveRecord::RecordNotFound errors because they are permanent" do

    ErrorObject.new.send_later(:throw)

    Delayed::Job.count.should == 1

    Delayed::Job.reserve_and_run_one_job

    Delayed::Job.count.should == 0

  end

  it "should store the object as string if its an active record" do
    story = Story.create :text => 'Once upon...'
    story.send_later(:tell)

    job =  Delayed::Job.find(:first)
    job.payload_object.class.should   == Delayed::PerformableMethod
    job.payload_object.object.should  == "AR:Story:#{story.id}"
    job.payload_object.method.should  == :tell
    job.payload_object.args.should    == []
    job.payload_object.perform.should == 'Once upon...'
  end

  it "should store arguments as string if they an active record" do

    story = Story.create :text => 'Once upon...'

    reader = StoryReader.new
    reader.send_later(:read, story)

    job =  Delayed::Job.find(:first)
    job.payload_object.class.should   == Delayed::PerformableMethod
    job.payload_object.method.should  == :read
    job.payload_object.args.should    == ["AR:Story:#{story.id}"]
    job.payload_object.perform.should == 'Epilog: Once upon...'
  end                 
  
  it "should call send later on methods which are wrapped with handle_asynchronously" do
    story = Story.create :text => 'Once upon...'
  
    Delayed::Job.count.should == 0
  
    story.whatever(1, 5)
  
    Delayed::Job.count.should == 1
    job =  Delayed::Job.find(:first)
    job.payload_object.class.should   == Delayed::PerformableMethod
    job.payload_object.method.should  == :whatever_without_send_later
    job.payload_object.args.should    == [1, 5]
    job.payload_object.perform.should == 'Once upon...'
  end

end
