ENV['PATH'] = ENV['PATH'] + ":/usr/sbin"
require 'celluloid/io'
require 'json'
require 'messages/terminal_control'

class Drone
  attr_accessor :drone_id, :name, :x, :y

  def initialize(monitor, drone_id)
    @monitor = monitor
    @drone_id = drone_id
    @name = "?"
    @x = 0
    @y = 0
    @crashed = false
  end

  def handle_data(string)
    return if crashed?
    cmd, *values = string.split
    case cmd
    when /^n/i
      @name = values.first[0]
      @monitor.async.moved(self, x, y)
    when /^p/i
      oldx, oldy = @x, @y
      @x = values[0].to_i
      @y = values[1].to_i
      @monitor.async.moved(self, oldx, oldy)
    when /^a/i
      ax = values[0].to_i
      ay = values[1].to_i
      @monitor.async.attack(ax, ay) if close_to(ax,ay)
    end
  end

  def close_to(ax, ay)
    (x-ax).abs <= 1 || (y-ay).abs <= 1
  end

  def crashed?
    @crashed
  end

  def crash
    @crashed = true
    send_frown("crash!")
  end

  def send_frown(frown_command)
    packet = { "id" => drone_id, "cmd" => "frown", "data" => frown_command }
    @monitor.send_data(packet.to_json + "\n")
  end
end

class MonitorServer
  include Celluloid::IO

  def initialize(options=nil)
    @drones = {}
    @tc = TerminalControl.new
    @tc.clear_screen
    @running = true
    @socket = TCPSocket.new('localhost', 8091)
    async.run
  end

  def running?
    @running
  end

  def run
    while running? && line = @socket.gets
      receive_line(line)
    end
    @running = false
    @socket.close
    Kernel.puts  "Server Shutting Down"
  end

  def receive_line(data)
    data = JSON.parse(data)
    drone_id = data["id"]
    drone =  @drones[drone_id]
    if ! drone
      drone = Drone.new(self, drone_id)
      @drones[drone_id] = drone
    end
    case data["cmd"]
    when 'connect'
      puts "New Drone Connected [#{info}]"
    when 'disconnect'
      put_at(drone.x, drone.y, "   ")
      @drones.delete(drone_id)
      puts "drone #{drone.name} disconnected [#{info}]"
    when 'frown'
      if drone.crashed?
        drone.crash
      else
        frown = data["data"]
        drone.handle_data(frown)
        drone.send_frown("name?") if drone.name == '?'
      end
    end
  end

  def send_data(data)
    return unless running?
    @socket.puts(data)
  end

  def report
    coords = @drones.
      map { |_, drone| "#{drone.x},#{drone.y}" }.
      select { |xy| xy != "0,0" }.
      join(";")
    frown_command = "radar #{coords}"
    @drones.each do |_, drone|
      drone.send_frown(frown_command)
    end
  end

  def moved(drone, oldx, oldy)
    put_at(oldx, oldy, "   ")
    put_at(drone.x, drone.y, ":" + drone.name[0] + ":")
    @tc.goto_home

    @drones.each do |other_id, other|
      if drone != other && (drone.x == other.x && drone.y == other.y)
        drone.crash
        other.crash
        puts "Crash Detected #{drone.name} / #{other.name}  [#{info}]"
      end
    end
  end

  def attack(ax, ay)
    @drones.each do |_, drone|
      if drone.x == ax && drone.y == ay
        puts "Drone #{drone.name} killed"
        drone.crash
      end
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

  def put_at(x, y, char)
    if x != 0
      @tc.goto(y+1, 3*x)
      printf char
    end
  end

  def puts(*args)
    @tc.goto_home
    @tc.clear_line
    super
  end
end

monitor = MonitorServer.new
sleep 2
while monitor.running?
  sleep 1
  monitor.async.report
end
