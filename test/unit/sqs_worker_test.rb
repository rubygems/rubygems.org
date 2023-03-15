require "test_helper"
require_relative "../../lib/shoryuken/sqs_worker"

class SqsWorkerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @sqs_worker = SqsWorker.new
    @body = {
      "Records" =>  [{
        "eventVersion" => "2.2",
        "eventSource" => "aws => s3",
        "awsRegion" => "us-west-2",
        "eventTime" => "The time, in ISO-8601 format, for example, 1970-01-01T00 => 00 => 00.000Z, when Amazon S3 finished processing the request",
        "eventName" => "event-type",
        "userIdentity" => {
          "principalId" => "Amazon-customer-ID-of-the-user-who-caused-the-event"
        },
        "requestParameters" => {
          "sourceIPAddress" => "ip-address-where-request-came-from"
        },
        "responseElements" => {
          "x-amz-request-id" => "Amazon S3 generated request ID",
          "x-amz-id-2" => "Amazon S3 host that processed the request"
        },
        "s3" => {
          "s3SchemaVersion" => "1.0",
          "configurationId" => "ID found in the bucket notification configuration",
          "bucket" => {
            "name" => "bucket-name",
            "ownerIdentity" => {
              "principalId" => "Amazon-customer-ID-of-the-bucket-owner"
            },
            "arn" => "bucket-ARN"
          },
          "object" => {
            "key" => "object-key",
            "size" => "object-size in bytes",
            "eTag" => "object eTag",
            "versionId" => "object version if bucket is versioning-enabled, otherwise null",
            "sequencer" =>  "a string representation of a hexadecimal value used to determine event sequence, only used with PUTs and DELETEs"
          }
        },
        "glacierEventData" =>  {
          "restoreEventData" =>  {
            "lifecycleRestorationExpiryTime" =>  "The time, in ISO-8601 format, for example, 1970-01-01T00 => 00 => 00.000Z, of Restore Expiry",
            "lifecycleRestoreStorageClass" =>  "Source storage class for restore"
          }
        }
      }]
    }
  end

  context "#perform" do
    should "create Logticket" do
      StatsD.expects(:increment).with("fastly_log_processor.s3_entry_fetched")
      StatsD.expects(:increment).with("fastly_log_processor.enqueued")
      StatsD.expects(:increment).with("rails.enqueue.active_job.success", 1,
        has_entry(tags: has_entries(queue: "default", priority: PRIORITIES[:stats], job_class: FastlyLogProcessorJob.name)))
      assert_enqueued_jobs 1, only: FastlyLogProcessorJob do
        @sqs_worker.perform(nil, @body)
      end

      log_ticket = LogTicket.last

      assert_equal "bucket-name", log_ticket.directory
      assert_equal "object-key", log_ticket.key
      assert_equal "pending", log_ticket.status
    end

    should "not create duplicate LogTicket" do
      duplicate_record = @body["Records"].first
      @body["Records"] << duplicate_record

      StatsD.expects(:increment).with("fastly_log_processor.s3_entry_fetched")
      StatsD.expects(:increment).with("fastly_log_processor.enqueued").twice
      StatsD.expects(:increment).with("fastly_log_processor.duplicated")
      StatsD.expects(:increment).with("rails.enqueue.active_job.success", 1,
        has_entry(tags: has_entries(queue: "default", priority: PRIORITIES[:stats], job_class: FastlyLogProcessorJob.name)))
      assert_enqueued_jobs 1, only: FastlyLogProcessorJob do
        @sqs_worker.perform(nil, @body)
      end
    end
  end
end
