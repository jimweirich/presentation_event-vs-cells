module Messages
  module PeriodicTimer
    def self.check_connection(connection)
      if connection.stale?
        connection.close_because "stale connection"
      end
    end

    def self.tick
      Messages.logger.log "Checking for stale connections"
      Messages::Connections.each do |k, connection|
        check_connection(connection)
      end
    end

    def self.start
      timer = EventMachine::PeriodicTimer.new(60) do
        tick
      end
    end
  end
end
