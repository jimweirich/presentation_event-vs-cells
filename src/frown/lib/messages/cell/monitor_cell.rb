require 'json'

class MonitorCell
  include Celluloid::IO

  finalizer :close_server

  attr_accessor :drones

  def initialize(host, port)
    puts "*** Starting Monitor Connection on #{host}:#{port}"
    @sock = nil
    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @drones = nil
    @server = TCPServer.new(host, port)
    async.run
  end

  def close_server
    @server.close if @server
  end

  def connect(drone_id)
    data = { "id" => drone_id, "cmd" => "connect" }.to_json
    @sock.puts(data) if @sock
  end

  def disconnect(drone_id)
    data = { "id" => drone_id, "cmd" => "disconnect" }.to_json
    @sock.puts(data) if @sock
  end

  def send_to_monitor(drone_id, msg)
    data = { "id" => drone_id, "cmd" => "frown", "data" => msg}.to_json
    @sock.puts(data) if @sock
  rescue Errno::EPIPE
    puts "*** Monitor Send Error: #{ex}"
    @sock = nil
  end

  def run
    loop { async.handle_connection(@server.accept) }
  end

  def handle_connection(socket)
    @sock = socket
    _, port, host = socket.peeraddr
    puts "*** Monitor connecting from #{host}:#{port}"
    while line = @sock.gets
      begin
        data = JSON.parse(line)
        drone_id = data["id"]
        if data["cmd"] == 'frown'
          msg = data["data"]
          @drones.async.send_to_drone(drone_id, msg) if @drones && msg
        else
          puts "*** UNRECOGNIZED COMMAND FROM MONITOR: <<<#{data}>>>"
        end
      rescue JSON::ParserError => ex
        puts "*** FAILED TO PARSE #{monitor_data.inspect}"
      end
    end
  rescue EOFError => ex
    puts "*** Monitor Receive Error: #{ex}"
  ensure
    puts "*** Monitor at #{host}:#{port} disconnected"
    @sock.close
    @sock = nil
  end
end
