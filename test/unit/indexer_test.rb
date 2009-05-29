require File.dirname(__FILE__) + '/../test_helper'

class IndexerTest < ActiveSupport::TestCase
  context "when generating the index" do
    setup do
      @gem = "gem"
      @tmpdir = "tmpdir"
      @time = Time.now
      regenerate_index
    end

    should "index properly" do
      mock(Dir).tmpdir { @tmpdir }

      mock.proxy(Gem::Indexer).new(Gemcutter.server_path, :build_legacy => false) do |indexer|
        mock(indexer).make_temp_directories
        mock(indexer).gem_file_list { [@gem] }
        stub(indexer).update_specs_index
        mock(indexer).compress_indicies
      end

      # Faking it out so there's a new gem to update
      mock(File).mtime(Gemcutter.server_path("specs.4.8")) { Time.at 1 }
      mock(File).mtime(@gem) { @time }

      # Loading the cached source index
      source_index_data = "source index data"
      source_index = "source index"
      stub(source_index).prerelease_gems
      mock(File).open(Gemcutter.server_path("source_index")) { source_index_data }
      mock(Marshal).load(source_index_data) { source_index }

      # Moving the compressed specs into place
      ["/specs.4.8",
       "/specs.4.8.gz",
       "/latest_specs.4.8",
       "/latest_specs.4.8.gz",
       "/prerelease_specs.4.8",
       "/prerelease_specs.4.8.gz"].each do |spec|

        mock(FileUtils).mv(File.join(@tmpdir, "gem_generate_index_#{$$}", spec),
          Gemcutter.server_path + "/",
          :force => true)

        mock(File).utime(@time, @time, Gemcutter.server_path + "/")
      end

      Cutter.indexer.update_index
    end
  end
end
