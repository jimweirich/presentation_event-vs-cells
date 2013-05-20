#!/usr/bin/ruby -wKU

require 'eventmachine'
require 'json'
require 'messages/terminal_control'

class Drone
  attr_accessor :drone_id, :name, :x, :y

  def initialize(conn, drone_id)
    @conn = conn
    @drone_id = drone_id
    @name = "?"
    @x = 0
    @y = 0
  end

  def handle_data(string)
    cmd, *values = string.split
    case cmd
    when /^n/i
      @name = values.first[0]
      @conn.moved(self, x, y)
    when /^p/i
      oldx, oldy = @x, @y
      @x = values[0].to_i
      @y = values[1].to_i
      @conn.moved(self, oldx, oldy)
    end
  end

  def send(msg)
    @conn.send_data({'id' => drone_id, 'msg' => msg}.to_json + "\n")
  end
end

class ServerReactor < EventMachine::Connection
  include EventMachine::Protocols::LineText2

  def initialize(options=nil)
    super
    @drones = {}
    @started = false
    @tc = TerminalControl.new
  end

  def post_init
    @tc.clear_screen
  end

  def unbind
    Kernel.puts  "Server Shutting Down"
    close_connection
    EventMachine.stop
  end

  def receive_line(data)
    drone_id, data = JSON.parse(data)
    drone =  @drones[drone_id]
    if ! drone
      drone = Drone.new(self, drone_id)
      @drones[drone_id] = drone
    end
    case data.first
    when '.connect'
      puts "New Drone Connected [#{info}]"
    when '.disconnect'
      put_at(drone.x, drone.y, "   ")
      @drones.delete(drone_id)
      puts "drone #{drone.name} disconnected [#{info}]"
    when '.data'
      drone.handle_data(data[1])
      drone.send("name?") if drone.name == '?'
    end
  end

  def put_at(x, y, char)
    if x != 0
      @tc.goto(y+1, 3*x)
      printf char
    end
  end

  def info
    result = @drones.size.to_s
    unless @drones.empty?
      names = @drones.map { |k,v| v.name }.join
      names = names[0..15] + "..." if names.size > 18
      result << "/" << names
    end
    result
  end

  def moved(drone, oldx, oldy)
    put_at(oldx, oldy, "   ")
    put_at(drone.x, drone.y, ":" + drone.name[0] + ":")
    @tc.goto_home

    @drones.each do |other_id, other|
      if drone != other && (drone.x == other.x && drone.y == other.y)
        drone.send("crash!")
        other.send("crash!")
        puts "Crash Detected #{drone.name} / #{other.name}  [#{@drones.size}]"
      end
    end
  end

  def puts(*args)
    @tc.goto_home
    @tc.clear_line
    super
  end

  def short_id(long_id)
    long_id.sub(/-[^-]+-[^-]+-[^-]+$/,'')
  end
end

EventMachine::run {
  trap('INT') { exit }

  EventMachine.error_handler { |e|
    Kernel.puts e.inspect
    Kernel.puts e.backtrace
    Kernel.puts
    Kernel.puts "Shutting down"
    EventMachine.stop_event_loop
  }

  channel = EventMachine::connect "localhost", 8091, ServerReactor
}
