require 'rake'
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
      @versions = create_list(:version, 3)
      @rubygems = @versions.map(&:rubygem)
    end

    should "not change already created downloads" do
      GemDownload.increment(100, version_id: 0, rubygem_id: @versions.first.rubygem_id)

      silence_stream(STDOUT) do
        run_rake_task("rubygems:update_download_counts")
      end
      assert_equal 100, GemDownload.count_for_rubygem(@rubygems.first)
    end

    should "create download counts for all gems" do
      GemDownload.delete_all
      @rubygems.each_with_index do |rubygem, download_count|
        Redis.current.incrby "downloads:rubygem:#{rubygem.name}", download_count
      end

      run_rake_task("rubygems:update_download_counts")

      assert_equal 0, GemDownload.count_for_rubygem(@rubygems[0].id)
      assert_equal 1, GemDownload.count_for_rubygem(@rubygems[1].id)
      assert_equal 2, GemDownload.count_for_rubygem(@rubygems[2].id)
    end
  end
end
