require 'json'
require 'eventmachine'

module Messages
  module DroneSession

    include EM::Protocols::LineText2
    include Messages::MainLogger

    TIMEOUT_SECONDS = 2*60 + 15

    def initialize(*args)
      super
      updated
      @reason = nil
      @first_time = true
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
      send_command_to_monitor("disconnect")
      Messages::Connections.delete(connection_id)
    end

    def receive_line(data)
      updated

      send_command_to_monitor("connect") if @first_time
      @first_time = false

      send_msg_data(data)
    end

    def send_frown_to_drone(frown_command)
      frown_command << "\n" unless frown_command =~ /\n\z/
      send_data(frown_command)
    end

    def send_command_to_monitor(command, data=nil)
      packet = { "id" => connection_id, 'cmd' => command }
      packet['data'] = data if data
      send_packet_to_monitor(packet)
    end

    def send_packet_to_monitor(packet)
      queue_name = "<--"
      log "[DRN] #{short_id} #{queue_name} #{packet.inspect}"
      if Messages.server
        Messages.server.enque(packet.to_json)
      else
        log "[DRN] No Server Found"
      end
    end

    def connection_id
      @_connection_id ||= UUID.generate
    end

    def short_id
      connection_id.sub(/-[^-]+-[^-]+-[^-]+$/,'')
    end

    def stale?
      (Time.now - @last_update) > TIMEOUT_SECONDS
    end

    private

    def updated
      @last_update = Time.now
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

    def send_msg_data(string)
      send_command_to_monitor("frown", string)
    end
  end
end
