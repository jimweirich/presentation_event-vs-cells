ENV['PATH'] = ENV['PATH'] + ":/usr/sbin"
require 'celluloid/io'

class DroneController
  include Celluloid::IO

  def initialize(name)
    @name = name
    @x = rand_coord
    @y = rand_coord
    @socket = TCPSocket.new('localhost', 8090)
    @running = true
    async.run
  end

  def running?
    @running
  end

  def run
    puts "Drone #{@name} flying"
    while running? && line = @socket.gets
      case line
      when /^name\?/
        send_data("name #{@name}")
      when /^crash!/
        puts "Drone #{@name} crashed\n"
        @running = false
      end
    end
    @socket.close
  end

  def rand_coord
    (1 + rand * 15.0).to_i
  end

  def rand_walk(p)
    result = p + rand(3) - 1
    result = 1 if result < 1
    result = 15 if result > 15
    result
  end

  def move
    @x = rand_walk(@x)
    @y = rand_walk(@y)
    send_data("position #{@x} #{@y}\n")
  end

  def send_data(string)
    @socket.puts(string) if running?
  end
end


name = ARGV.shift
if name.nil?
  puts "Usage: drone.rb NAME"
  exit(1)
end

drone = DroneController.new(name)

while drone.running?
  sleep 1.0
  drone.move
end
