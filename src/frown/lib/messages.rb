require 'json'

require 'uuid'
require 'logger'

require 'messages/logger'
require 'messages/drone_session'
require 'messages/monitor_session'
require 'messages/periodic_timer'

module Messages
  Connections = {}

  def self.server
    @server
  end

  def self.server=(server)
    @server = server
  end

  def self.shutdown(message)
    Messages.logger.log("[SYS] #{message}")
    Messages::Connections.each do |connid, connection|
      connection.close_because("shutdown")
    end
    EM.stop_event_loop
    Messages.logger.log("[SYS] Shutting down")
  end

  def self.error_handler
    lambda { |e|
      puts e.inspect
      Messages.logger.log "[ERR] #{e.inspect}"
      Messages.logger.log e.backtrace

      Messages.shutdown("fatal error")
    }
  end
end
