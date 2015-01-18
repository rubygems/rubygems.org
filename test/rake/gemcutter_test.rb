require "test_helper"

class GemcutterTest < ActiveSupport::TestCase
  setup do
    Rake.application.rake_require "lib/tasks/gemcutter", [Rails.root.to_s]
    Rake::Task.define_task(:environment)
  end

  def run_rake_task(task_name)
    Rake::Task["gemcutter:#{task_name}"].reenable
    Rake.application.invoke_task "gemcutter:#{task_name}"
  end

  context "rubygems" do
    setup do
      @rubygems = create_list(:rubygem_with_downloads, 3, downloads: 0)
    end

    def update_download_counts
      run_rake_task("rubygems:update_download_counts")
    end

    should "update download counts for all gems" do
      @rubygems.each_with_index do |rubygem, download_count|
        Redis.current.incrby "downloads:rubygem:#{rubygem.name}", download_count
      end

      update_download_counts

      assert_equal 0, @rubygems[0].reload["downloads"]
      assert_equal 1, @rubygems[1].reload["downloads"]
      assert_equal 2, @rubygems[2].reload["downloads"]
    end

    teardown do
      @rubygems.each(&:destroy)
    end
  end
end
