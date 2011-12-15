require 'net/http'
require 'net/smtp'
require 'open-uri'
# Example:
#   begin
#     some http call
#   rescue *HTTP_ERRORS => error
#     notify_airbrake error
#   end

HTTP_ERRORS = [Timeout::Error,
               Errno::EINVAL,
               Errno::ECONNRESET,
               EOFError,
               Net::HTTPBadResponse,
               Net::HTTPHeaderSyntaxError,
               Net::ProtocolError,
               OpenURI::HTTPError]

SMTP_SERVER_ERRORS = [TimeoutError,
                      IOError,
                      Net::SMTPUnknownError,
                      Net::SMTPServerBusy,
                      Net::SMTPAuthenticationError]

SMTP_CLIENT_ERRORS = [Net::SMTPFatalError,
                      Net::SMTPSyntaxError]

SMTP_ERRORS = SMTP_SERVER_ERRORS + SMTP_CLIENT_ERRORS
