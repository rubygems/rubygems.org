class SqsWorker
  include Shoryuken::Worker

  shoryuken_options queue: ENV['SQS_QUEUE'], body_parser: :json, auto_delete: true

  def perform(_sqs_msg, body)
    s3_objects = body['Records'].map do |record|
      [
        record['s3']['bucket']['name'],
        record['s3']['object']['key']
      ]
    end

    ActiveRecord::Base.transaction do
      s3_objects.each do |bucket, key|
        Delayed::Job.enqueue FastlyLogProcessor.new(bucket, key), priority: PRIORITIES[:stats]
      end
    end
  end
end
