module AWS
  module S3
    
    # Abstract super class of all AWS::S3 exceptions
    class S3Exception < StandardError
    end
    
    # All responses with a code between 300 and 599 that contain an <Error></Error> body are wrapped in an
    # ErrorResponse which contains an Error object. This Error class generates a custom exception with the name
    # of the xml Error and its message. All such runtime generated exception classes descend from ResponseError
    # and contain the ErrorResponse object so that all code that makes a request can rescue ResponseError and get
    # access to the ErrorResponse.
    class ResponseError < S3Exception
      attr_reader :response
      def initialize(message, response)
        @response = response
        super(message)
      end
    end
    
    #:stopdoc:
    
    # Most ResponseError's are created just time on a need to have basis, but we explicitly define the
    # InternalError exception because we want to explicitly rescue InternalError in some cases.
    class InternalError < ResponseError
    end
    
    class NoSuchKey < ResponseError
    end
    
    class RequestTimeout < ResponseError
    end
    
    # Abstract super class for all invalid options.
    class InvalidOption < S3Exception
    end
    
    # Raised if an invalid value is passed to the <tt>:access</tt> option when creating a Bucket or an S3Object.
    class InvalidAccessControlLevel < InvalidOption
      def initialize(valid_levels, access_level)
        super("Valid access control levels are #{valid_levels.inspect}. You specified `#{access_level}'.")
      end
    end
    
    # Raised if either the access key id or secret access key arguments are missing when establishing a connection.
    class MissingAccessKey < InvalidOption
      def initialize(missing_keys)
        key_list = missing_keys.map {|key| key.to_s}.join(' and the ')
        super("You did not provide both required access keys. Please provide the #{key_list}.")
      end
    end
    
    # Raised if a request is attempted before any connections have been established.
    class NoConnectionEstablished < S3Exception
    end
    
    # Raised if an unrecognized option is passed when establishing a connection.
    class InvalidConnectionOption < InvalidOption
      def initialize(invalid_options)
        message = "The following connection options are invalid: #{invalid_options.join(', ')}. "    +
                  "The valid connection options are: #{Connection::Options::VALID_OPTIONS.join(', ')}."
        super(message)
      end
    end
    
    # Raised if an invalid bucket name is passed when creating a new Bucket.
    class InvalidBucketName < S3Exception
      def initialize(invalid_name)
        message = "`#{invalid_name}' is not a valid bucket name. "      + 
                  "Bucket names must be between 3 and 255 bytes and "   +
                  "can contain letters, numbers, dashes and underscores."
        super(message)
      end
    end
    
    # Raised if an invalid key name is passed when creating an S3Object.
    class InvalidKeyName < S3Exception
      def initialize(invalid_name)
        message = "`#{invalid_name}' is not a valid key name. "   + 
                  "Key names must be no more than 1024 bytes long."
        super(message)
      end
    end
    
    # Raised if an invalid value is assigned to an S3Object's specific metadata name.
    class InvalidMetadataValue < S3Exception
      def initialize(invalid_names)
        message = "The following metadata names have invalid values: #{invalid_names.join(', ')}. " +
                  "Metadata can not be larger than 2kilobytes."
        super(message)
      end
    end
    
    # Raised if the current bucket can not be inferred when not explicitly specifying the target bucket in the calling
    # method's arguments.
    class CurrentBucketNotSpecified < S3Exception
      def initialize(address)
        message = "No bucket name can be inferred from your current connection's address (`#{address}')"
        super(message)
      end
    end
    
    # Raised when an orphaned S3Object belonging to no bucket tries to access its (non-existant) bucket.
    class NoBucketSpecified < S3Exception
      def initialize
        super('The current object must have its bucket set')
      end
    end
    
    # Raised if an attempt is made to save an S3Object that does not have a key set.
    class NoKeySpecified < S3Exception
      def initialize
        super('The current object must have its key set')
      end
    end
    
    # Raised if you try to save a deleted object.
    class DeletedObject < S3Exception
      def initialize
        super('You can not save a deleted object')
      end
    end
    
    class ExceptionClassClash < S3Exception #:nodoc:
      def initialize(klass)
        message = "The exception class you tried to create (`#{klass}') exists and is not an exception"
        super(message)
      end
    end
    
    #:startdoc:
  end
end