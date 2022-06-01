require "test_helper"

class UpdateVersionsFileTest < ActiveSupport::TestCase
  setup do
    @tmp_versions_file = Tempfile.new("tmp_versions_file")
    tmp_path = @tmp_versions_file.path
    Rails.application.config.rubygems.stubs(:[]).with("versions_file_location").returns(tmp_path)
    Gemcutter::Application.load_tasks
  end

  def update_versions_file
    freeze_time do
      @created_at = Time.now.utc.iso8601
      Rake::Task["compact_index:update_versions_file"].invoke
    end
  end

  teardown do
    Rake::Task["compact_index:update_versions_file"].reenable
    @tmp_versions_file.unlink
  end

  context "file header" do
    setup do
      update_versions_file
    end

    should "use today's timestamp as header" do
      expected_header = "created_at: #{@created_at}\n---\n"
      assert_equal expected_header, @tmp_versions_file.read
    end
  end

  context "single gem" do
    setup { @rubygem = create(:rubygem, name: "rubyrubyruby") }

    context "platform release" do
      setup do
        create(:version,
          rubygem:       @rubygem,
          created_at:    2.minutes.ago,
          number:        "0.0.1",
          info_checksum: "13q4e1")
        create(:version,
          rubygem:       @rubygem,
          created_at:    1.minute.ago,
          number:        "0.0.1",
          info_checksum: "qw212r",
          platform:      "jruby")

        update_versions_file
      end

      should "include platform release" do
        expected_output = "rubyrubyruby 0.0.1,0.0.1-jruby qw212r\n"
        assert_equal expected_output, @tmp_versions_file.readlines[2]
      end
    end

    context "order" do
      setup do
        1.upto(3) do |i|
          create(:version,
            rubygem:       @rubygem,
            created_at:    i.minutes.ago,
            number:        "0.0.#{4 - i}",
            info_checksum: "13q4e#{i}")
        end

        update_versions_file
      end

      should "order by created_at and use last released version's info_checksum" do
        expected_output = "rubyrubyruby 0.0.1,0.0.2,0.0.3 13q4e1\n"
        assert_equal expected_output, @tmp_versions_file.readlines[2]
      end
    end

    context "yanked version" do
      setup do
        create(:version,
          rubygem:       @rubygem,
          created_at:    5.minutes.ago,
          number:        "0.0.1",
          info_checksum: "qw212r")
        create(:version,
          indexed:              false,
          rubygem:              @rubygem,
          created_at:           3.minutes.ago,
          yanked_at:            1.minute.ago,
          number:               "0.0.2",
          info_checksum:        "sd12q",
          yanked_info_checksum: "qw212r")
        Rake::Task["compact_index:update_versions_file"].invoke
      end

      should "not include yanked version" do
        expected_output = "rubyrubyruby 0.0.1 qw212r\n"
        assert_equal expected_output, @tmp_versions_file.readlines[2]
      end
    end

    context "yanked version isn't the latest version" do
      setup do
        create(:version,
          rubygem:       @rubygem,
          created_at:    5.seconds.ago,
          number:        "0.1.1",
          info_checksum: "zqw212r")
        create(:version,
          indexed:       false,
          rubygem:       @rubygem,
          created_at:    4.seconds.ago,
          yanked_at:     2.seconds.ago,
          number:        "0.1.2",
          info_checksum: "zsd12q",
          yanked_info_checksum: "zab45d")
        create(:version,
          rubygem:       @rubygem,
          created_at:    3.seconds.ago,
          number:        "0.1.3",
          info_checksum: "zrt13y")

        update_versions_file
      end

      should "not include yanked version" do
        expected_output = "rubyrubyruby 0.1.1,0.1.3 zab45d\n"
        assert_equal expected_output, @tmp_versions_file.readlines[2]
      end
    end

    context "no public versions" do
      setup do
        create(:version,
          indexed:       false,
          rubygem:       @rubygem,
          created_at:    4.seconds.ago,
          yanked_at:     2.seconds.ago,
          number:        "0.1.2",
          info_checksum: "zsd12q",
          yanked_info_checksum: "zab45d")

        update_versions_file
      end

      should "not include yanked version" do
        refute_includes "rubyrubyruby", @tmp_versions_file.read
      end
    end
  end

  context "multiple gems" do
    setup do
      3.times do |i|
        create(:rubygem, name: "rubygem#{i}").tap do |gem|
          create(:version, rubygem: gem, created_at: 4.seconds.ago, number: "0.0.1", info_checksum: "13q4e#{i}")
        end
      end

      update_versions_file
    end

    should "put each gem on new line" do
      expected_output = <<~VERSIONS_FILE
        created_at: #{@created_at}
        ---
        rubygem0 0.0.1 13q4e0
        rubygem1 0.0.1 13q4e1
        rubygem2 0.0.1 13q4e2
      VERSIONS_FILE
      assert_equal expected_output, @tmp_versions_file.read
    end
  end
end
