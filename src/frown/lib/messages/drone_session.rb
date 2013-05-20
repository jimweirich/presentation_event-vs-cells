require 'json'
require 'eventmachine'

module Messages
  module DroneSession

    include EM::Protocols::LineText2
    include Messages::MainLogger

    IN_SETUP_TIMEOUT_SECONDS = 5*60
    TIMEOUT_SECONDS = 2*60 + 15
    INITIAL_COMMAND_DELAY_SECONDS = 10

    def initialize(*args)
      super
      updated
      @reason = nil
      @setup = false
    end

    def post_init
      log_ip_address
      Messages::Connections[connection_id] = self
    end

    def close_because(reason)
      log "      #{short_id} Closing (#{reason})"
      @reason = reason
      EventMachine::Timer.new(5) do
        close_connection
      end
    end

    def unbind
      send_to_monitor(".disconnect", @reason || "external drop") if msg_received?
      Messages::Connections.delete(connection_id)
    end

    def receive_line(data)
      updated

      send_to_monitor(".connect") unless msg_received?
      msg_received

      decoded = Messages::MsgFrame.decode(data)
      @setup = true if authorized_command?(decoded)
      send_msg_data(decoded)
    end

    def send_to_monitor(*data)
      queue_name = "<--"
      log "[DRN] #{short_id} #{queue_name} #{data.inspect}"
      serialized_data = [connection_id, data].to_json
      if Messages.server
        Messages.server.enque(serialized_data)
      else
        log "[DRN] No Server Found"
      end
    end

    def stale?
      (Time.now - @last_update) > (@setup ? TIMEOUT_SECONDS : IN_SETUP_TIMEOUT_SECONDS)
    end

    def connection_id
      @_connection_id ||= UUID.generate
    end

    def short_id
      connection_id.sub(/-[^-]+-[^-]+-[^-]+$/,'')
    end

    private

    def updated
      @last_update = Time.now
    end

    def msg_received?
      @_msg_received
    end

    def msg_received
      @_msg_received = true
    end

    def log_ip_address
      peername = get_peername
      if peername
        port, ip = Socket.unpack_sockaddr_in(peername)
        log "      Connection from #{ip}:#{port} (#{short_id})"
      else
        log "      Connection from UNKNOWN IP ADDRESS (#{short_id})"
      end
    end

    def authorized_command?(command)
      command.start_with?("authorized")
    end

    def first_command?(command)
      command.start_with?("challenge")
    end

    def send_msg_data(string)
      if first_command?(string)
        send_in(INITIAL_COMMAND_DELAY_SECONDS, string)
      else
        send_to_monitor(".data", string)
      end
    end

    def send_in(seconds, string)
      EventMachine::Timer.new(seconds) do
        send_to_monitor(string)
      end
    end

  end
end
