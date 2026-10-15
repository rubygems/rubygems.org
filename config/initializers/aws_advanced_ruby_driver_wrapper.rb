# frozen_string_literal: true

# The wrapper logs to $stderr by default. Send it through Semantic Logger so its
# Blue/Green switchover summary ends up in our logs.
AwsAdvancedRubyDriverWrapper.logger = SemanticLogger[AwsAdvancedRubyDriverWrapper]
