module Messages
  def self.logger
    Messages::MainLogger
  end

  module MainLogger
    LOG_FILE = File.join(File.dirname(__FILE__), "../../log/messages.log")

    def self.log(*args)
      message = args.shift
      outstring = ["#{log_time} #{message}", args].flatten.join("\n")
      outstring << "\n"
      (@logger ||= ::Logger.new(LOG_FILE)) << outstring
    end

    def self.log_time
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    def log(*args)
      Messages.logger.log(*args)
    end
  end
end
