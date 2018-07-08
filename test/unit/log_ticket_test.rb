require 'test_helper'

class LogTicketTest < ActiveSupport::TestCase
  setup do
    @log_ticket = LogTicket.create!(directory: "test", key: "foo", status: "pending")
  end

  should "not allow duplicate directory and key" do
    assert_raise ActiveRecord::RecordNotUnique do
      LogTicket.create!(directory: "test", key: "foo")
    end
  end

  should "allow different keys for the same directory" do
    LogTicket.create!(directory: "test", key: "bar")
    LogTicket.create!(directory: "test", key: "baz")
  end

  context "#pop" do
    setup do
      LogTicket.create!(directory: "test/2", key: "bar", status: "pending")
    end

    context "without any key" do
      should "pop the first inputed" do
        ticket = LogTicket.pop
        assert_equal "foo", ticket.key
      end
    end

    context "with a key" do
      should "pop the key" do
        ticket = LogTicket.pop(key: "bar")
        assert_equal "bar", ticket.key
      end
    end

    context "with a directory" do
      should "pop the first entry" do
        LogTicket.create!(directory: "test/2", key: "boo", status: "pending")

        ticket = LogTicket.pop(directory: "test/2")
        assert_equal "bar", ticket.key
      end
    end

    should "change the status" do
      ticket = LogTicket.pop
      assert_equal "processing", ticket.status
    end

    should "return nil after no more items are in the queue" do
      2.times { LogTicket.pop }
      assert_nil LogTicket.pop
    end
  end

  context "fs" do
    context "local" do
      setup do
        @log_ticket.update!(backend: "local", key: "sample_logs/fastly-fake.log")
        @sample_log = Rails.root.join('test', 'sample_logs', 'fastly-fake.log').read
      end

      should "return a local fs" do
        assert_kind_of RubygemFs::Local, @log_ticket.fs
      end

      should "set the right base directory" do
        assert_equal "test", @log_ticket.fs.base_dir
      end

      should "body return the file body" do
        assert_equal @sample_log, @log_ticket.body
      end
    end

    context "s3" do
      setup do
        @log_ticket.update!(backend: "s3", key: "sample_logs/fastly-fake.log")
        @sample_log = Rails.root.join('test', 'sample_logs', 'fastly-fake.log').read
        Aws.config[:s3] = {
          stub_responses: { get_object: { body: @sample_log } }
        }
      end

      should "return a s3 fs" do
        assert_kind_of RubygemFs::S3, @log_ticket.fs
      end

      should "set the right bucket" do
        assert_equal "test", @log_ticket.fs.bucket
      end

      should "body return the file body" do
        assert_equal @sample_log, @log_ticket.body
      end
    end
  end
end
