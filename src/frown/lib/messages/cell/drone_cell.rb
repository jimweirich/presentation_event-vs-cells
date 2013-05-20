require 'messages/cell/line_protocol'
require 'messages/msg_frame'

class DroneCell
  include Celluloid::IO

  def initialize(monitor, host, port)
    puts "*** Starting Drone Connection Server on #{host}:#{port}"

    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @monitor = monitor
    @server = TCPServer.new(host, port)
    @drones = {}
    run!
  end

  def send_to_drone(drone_id, msg)
    ios = @drones[drone_id]
    ios.puts(msg) if ios
  end

  def finalize
    @server.close if @server
  end

  def run
    loop { handle_connection! @server.accept }
  end

  def handle_connection(socket)
    ios = LineProtocol.new(socket)
    _, port, host = socket.peeraddr
    drone_id = UUID.generate
    @drones[drone_id] = ios
    puts "Created connection for #{drone_id} from #{host}:#{port}"
    @monitor.async.connect(drone_id)
    loop {
      data = ios.gets
      decoded = Messages::MsgFrame.decode(data)
      @monitor.async.send_to_server(drone_id, decoded.strip)
    }
  rescue EOFError, Errno::ECONNRESET
    @monitor.async.disconnect(drone_id)
    puts "Drone Connection #{drone_id} dropped"
  end
end
