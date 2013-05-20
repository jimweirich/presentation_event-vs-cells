require 'json'

class MonitorCell
  include Celluloid::IO

  attr_accessor :drones

  def initialize(host, port)
    puts "*** Starting Drone Server Connection on #{host}:#{port}"
    @sock = nil
    @ios = nil
    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @drones = nil
    @server = TCPServer.new(host, port)
    async.run
  end

  def finalize
    @server.close if @server
  end

  def connect(drone_id)
    data = [drone_id, [".connect"]].to_json
    @ios.puts(data) if @ios
  end

  def disconnect(drone_id)
    data = [drone_id, [".disconnect"]].to_json
    @ios.puts(data) if @ios
  end

  def send_to_server(drone_id, msg)
    data = [drone_id, [".data", msg]].to_json
    @ios.puts(data) if @ios
  rescue Errno::EPIPE
    @ios = nil
  end

  def run
    loop { async.handle_connection(@server.accept) }
  end

  def handle_connection(socket)
    @sock = socket
    @ios = LineProtocol.new(@sock)
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    loop {
      begin
        monitor_data = @ios.gets
        data = JSON.parse(monitor_data)
        drone_id = data["id"]
        msg = data["msg"]
        @drones.async.send_to_drone(drone_id, msg) if @drones
      rescue JSON::ParserError => ex
        puts "*** FAILED TO PARSE #{monitor_data.inspect}"
      end
    }
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
  end
end
