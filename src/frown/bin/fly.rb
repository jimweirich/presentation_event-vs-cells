#!/usr/bin/ruby -wKU

if ARGV.empty?
  puts "Usage: fly.rb N"
  exit(1)
end

NAMES = ('A'..'Z').to_a +
  ('0'..'9').to_a +
  ('a'..'z').to_a +
  ['+', '-', '=', '*']

n = ARGV.first.to_i

threads = (0...n).map do |i|
  Thread.new do
    system "ruby -Ilib bin/drone.rb '#{NAMES[i % NAMES.size]}'"
  end
end

threads.each do |t| t.join end
