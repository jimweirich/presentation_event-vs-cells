#!/usr/bin/ruby -wKU

require 'eventmachine'


class DroneReactor < EventMachine::Connection
  include EventMachine::Protocols::LineText2

  def initialize(name)
    super
    @name = name
    @x = rand_coord
    @y = rand_coord
  end

  def post_init
    puts "Drone #{@name} flying"
    sleep(rand)
    EventMachine::PeriodicTimer.new(1) do
      move
    end
  end

  def unbind
    close_connection
    EventMachine.stop
  end

  def receive_line(data)
    if data == 'name?'
      send_data("name #{@name}")
    elsif data == 'crash!'
      puts "Drone #{@name} crashed\n"
      close_connection
      EventMachine.stop
    end
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
end


name = ARGV.shift
if name.nil?
  puts "Usage: drone.rb NAME"
  exit(1)
end

EventMachine::run {
  trap('INT') { exit }

  EventMachine.error_handler { |e|
    puts e.inspect
    puts e.backtrace
    puts
    puts "Shutting down"
    EventMachine.stop_event_loop
  }

  EventMachine::connect "localhost", 8090, DroneReactor, name
}
