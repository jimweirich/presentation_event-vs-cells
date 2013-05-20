#!/usr/bin/ruby -wKU

def exit_with_error(error_message)
  puts error_message
  usage
  exit(1)
end

def usage
  puts "Usage: fly.rb [-ec] N"
end

NAMES = ('A'..'Z').to_a +
  ('0'..'9').to_a +
  ('a'..'z').to_a +
  ['+', '-', '=', '*']

number = 0
style = "evented"
ARGV.each do |arg|
  case arg
  when '-c'
    style = "celluloid"
  when '-e'
    style = "evented"
  when /^\d+$/
    number = arg.to_i
  else
    exit_with_error "ERROR: Unrecognized argument '#{arg}'"
  end
end

exit_with_error "Please specify a number of drones to fly" if number <= 0

threads = (0...number).map do |i|
  Thread.new do
    system "ruby -Ilib bin/drone_#{style}.rb '#{NAMES[i % NAMES.size]}'"
  end
end

threads.each do |t| t.join end
