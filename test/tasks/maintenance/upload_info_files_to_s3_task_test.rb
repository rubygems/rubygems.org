# frozen_string_literal: true

require "test_helper"

class Maintenance::UploadInfoFilesToS3TaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#process performs a task iteration" do
    rubygem = create(:rubygem)
    assert_enqueued_jobs 1, only: UploadInfoFileJob do
      assert_enqueued_with(job: UploadInfoFileJob, args: [{ rubygem_name: rubygem.name }]) do
        Maintenance::UploadInfoFilesToS3Task.process(rubygem)
      end
    end
  end

  test "#collection returns the elements to process" do
    create(:rubygem)
    rubygem = create(:rubygem)
    create(:version, rubygem: rubygem)

    assert_same_elements [rubygem], Maintenance::UploadInfoFilesToS3Task.collection
  end
end
