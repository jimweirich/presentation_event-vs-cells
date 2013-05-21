ENV['PATH'] = ENV['PATH'] + ":/usr/sbin"
require 'celluloid/io'

class DroneController
  include Celluloid::IO

  attr_reader :x, :y

  def initialize(name, host=nil)
    host = host || 'localhost'
    @name = name
    @x = rand_coord
    @y = rand_coord
    @socket = TCPSocket.new(host, 8090)
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
      when /^radar/
        coords = parse_radar(line)
        move_away(coords)
      end
    end
    @socket.close
  end

  def move_away(coords)
    coords = coords.reject { |cx, cy| cx==x && cy==y }
    best_move = find_best_move(possible_moves, coords)
    move_to(*best_move)
  end

  def possible_moves
    [ [x,y],   [x-1, y],   [x+1, y],
      [x,y-1], [x-1, y-1], [x+1, y-1],
      [x,y+1], [x-1, y+1], [x+1, y+1],
    ].select { |x, y| x >= 1 && x <= 15 && y >= 1 && y <= 15 }
  end

  def find_best_move(possible_moves, coords)
    ranked_moves = possible_moves.map { |mx, my|
      dist_coords = coords.map { |cx, cy| [dist(mx, my, cx, cy), [mx, my]] }.sort
      dist_coords.first
    }.compact.sort
    if ranked_moves.empty?
      [x, y]
    else
      ranked_moves.last[1]
    end
  end

  def parse_radar(line)
    line.scan(/(\d+),(\d+)/).map { |x, y|
      [x.to_i, y.to_i]
    }
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

  def move_to(x, y)
    @x = x
    @y = y
    send_data("position #{@x} #{@y}\n")
  end

  def random_move
    move_to(rand_walk(@x), rand_walk(@y))
  end

  def dist(x1, y1, x2, y2)
    Math.sqrt((x1-x2)**2 + (y1-y2)**2)
  end

  def send_data(string)
    @socket.puts(string) if running?
  end
end


if $0 == __FILE__
  name, host = ARGV
  if name.nil?
    puts "Usage: drone.rb NAME [host]"
    exit(1)
  end

  drone = DroneController.new(name, host)
  sleep 1

  while drone.running?
    sleep 1
  end
end
