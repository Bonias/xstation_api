require 'logger'

module XStore
  module Logger
    def log message
      logger.info("[xstore-client] #{message}") if logging?
    end

    def logger #:nodoc:
      @logger ||= options[:logger] || ::Logger.new(STDOUT)
    end

    def logger=(logger)
      @logger = logger
    end

    def logging? #:nodoc:
      options[:log]
    end


    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def error(message)
      log(:error, message)
    end

    def fatal(message)
      log(:fatal, message)
    end

    protected
    def log(method, message)
      if self.respond_to?(:logging) ? self.logging : AMQ::Client::Logging.logging
        self.client.logger.__send__(method, message)
        message
      end
    end

  end
end