require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::Indexer do
  before do
    @gem = "gem"
    @tmpdir = "tmpdir"
    @time = Time.now
    regenerate_index
  end

  it "should index properly" do
    mock(Dir).tmpdir { @tmpdir }

    mock.proxy(Gem::Indexer).new(Gem::Cutter.server_path, :build_legacy => false) do |indexer|
      mock(indexer).make_temp_directories
      mock(indexer).gem_file_list { [@gem] }
      stub(indexer).update_specs_index
      mock(indexer).compress_indicies
    end

    # Faking it out so there's a new gem to update
    mock(File).mtime(Gem::Cutter.server_path("specs.4.8")) { Time.at 1 }
    mock(File).mtime(@gem) { @time }

    # Loading the cached source index
    source_index_data = "source index data"
    source_index = "source index"
    stub(source_index).prerelease_gems
    mock(File).open(Gem::Cutter.server_path("source_index")) { source_index_data }
    mock(Marshal).load(source_index_data) { source_index }

    # Moving the compressed specs into place
    ["/specs.4.8",
     "/specs.4.8.gz",
     "/latest_specs.4.8",
     "/latest_specs.4.8.gz",
     "/prerelease_specs.4.8",
     "/prerelease_specs.4.8.gz"].each do |spec|

      mock(FileUtils).mv(File.join(@tmpdir, "gem_generate_index_#{$$}", spec),
        Gem::Cutter.server_path + "/",
        :force => true)

      mock(File).utime(@time, @time, Gem::Cutter.server_path + "/")
    end


    Gem::Cutter.indexer.update_index
  end
end
