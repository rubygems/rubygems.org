require 'test_helper'

class TestApplication < Test::Unit::TestCase
  def run_application(*arguments)
    original_stdout = $stdout
    original_stderr = $stderr

    fake_stdout = StringIO.new
    fake_stderr = StringIO.new

    $stdout = fake_stdout
    $stderr = fake_stderr

    result = nil
    begin
      result = Jeweler::Generator::Application.run!(*arguments)
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    @stdout = fake_stdout.string
    @stderr = fake_stderr.string

    result
  end

  def self.should_exit_with_code(code)
    should "exit with code #{code}" do
      assert_equal code, @result
    end
  end

  context "called without any args" do
    setup do
      @result = run_application
    end

    should_exit_with_code 1

    should 'display usage on stderr' do
      assert_match 'Usage:', @stderr
    end

    should 'not display anything on stdout' do
      assert_equal '', @stdout.squeeze.strip
    end
  end

  def build_generator(name = 'zomg', options = {:testing_framework => :shoulda})
    stub(Git).global_config() do
      {'user.name' => 'John Doe', 'user.email' => 'john@example.com', 'github.user' => 'johndoe', 'github.token' => 'yyz'}
    end

    Jeweler::Generator.new(name, options)
  end

  context "called with -h" do
    setup do
      @generator = build_generator
      stub(@generator).run
      stub(Jeweler::Generator).new { raise "Shouldn't have made this far"}

      assert_nothing_raised do
        @result = run_application("-h")
      end
    end

    should_exit_with_code 1

    should 'display usage on stderr' do
      assert_match 'Usage:', @stderr
    end

    should 'not display anything on stdout' do
      assert_equal '', @stdout.squeeze.strip
    end
  end

  context "called with --invalid-argument" do
    setup do
      @generator = build_generator
      stub(@generator).run
      stub(Jeweler::Generator).new { raise "Shouldn't have made this far"}

      assert_nothing_raised do
        @result = run_application("--invalid-argument")
      end
    end

    should_exit_with_code 1

    should 'display invalid argument' do
      assert_match '--invalid-argument', @stderr
    end

    should 'display usage on stderr' do
      assert_match 'Usage:', @stderr
    end

    should 'not display anything on stdout' do
      assert_equal '', @stdout.squeeze.strip
    end
  end

  context "when called with repo name" do
    setup do
      @options = {:testing_framework => :shoulda, :documentation_framework => :rdoc}
      @generator = build_generator('zomg', @options)

      stub(@generator).run
      stub(Jeweler::Generator).new { @generator }
    end

    should 'return exit code 0' do
      result = run_application("zomg")
      assert_equal 0, result
    end
    
    should 'create generator with repo name and no options' do
      run_application("zomg")

      assert_received Jeweler::Generator do |subject|
        subject.new('zomg', @options)
      end
    end

    should 'run generator' do
      run_application("zomg")

      assert_received(@generator) {|subject| subject.run }
    end

    should 'not display usage on stderr' do
      assert_no_match /Usage:/, @stderr
    end
  end

end
