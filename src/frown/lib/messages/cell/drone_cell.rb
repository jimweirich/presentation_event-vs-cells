class DroneCell
  include Celluloid::IO

  finalizer :close_server

  def initialize(monitor, host, port)
    puts "*** Starting Drone Connection Server on #{host}:#{port}"

    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @monitor = monitor
    @server = TCPServer.new(host, port)
    @drones = {}
    @next_id = "0000"
    async.run
  end

  def send_to_drone(drone_id, msg)
    ios = @drones[drone_id]
    ios.puts(msg) if ios
  end

  def close_server
    @server.close if @server
  end

  def run
    loop { async.handle_connection(@server.accept) }
  end

  def assign_id
    @next_id = @next_id.succ
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    drone_id = assign_id
    @drones[drone_id] = socket
    puts "Created connection for #{drone_id} from #{host}:#{port}"
    @monitor.async.connect(drone_id)
    while line = socket.gets
      @monitor.async.send_to_monitor(drone_id, line.strip)
    end
  rescue EOFError, Errno::ECONNRESET => ex
    puts "Error on Drone #{drone_id}: #{ex}"
  ensure
    @monitor.async.disconnect(drone_id)
    puts "Drone #{drone_id} disconnected"
    @drones[drone_id] = nil
  end
end
