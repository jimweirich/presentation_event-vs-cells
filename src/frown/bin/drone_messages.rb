require 'rubygems'
require 'yaml'
require 'messages'

def inform(msg)
  puts msg
  Messages.logger.log(msg)
end

def symbolize(obj)
  case obj
  when Hash
    result = {}
    obj.each do |key, value|
      result[key.to_sym] = symbolize(value)
    end
    result
  else
    obj
  end
end

def read_config(fn)
  return {} if ! File.exist?(fn)

  config = YAML.load_file(fn) || {}
  symbolize(config)
end

BINDIR = File.dirname($0)
HOMEDIR = File.dirname(BINDIR)

CONFIG_FILE = File.join(HOMEDIR, 'config/messages.yml')
CONFIG = read_config(CONFIG_FILE)

inform "Messages ... #{CONFIG[:env]}"

socket_options = CONFIG[:socket] || {}
socket_max = (socket_options[:max] || 5000).to_i

max_files = EventMachine.set_descriptor_table_size
if (max_files < socket_max)
  inform "File descriptor table size #{max_files} limits max# sockets, attempting change to #{socket_max}"
  max_files = EventMachine.set_descriptor_table_size(socket_max)
end
inform "File descriptor table size is now #{max_files}"

EventMachine.epoll

EventMachine.run {
  socket_host = socket_options[:host] || "0.0.0.0"
  socket_port = (socket_options[:port] || 8090).to_i
  inform "SOCKET Options: #{socket_options.inspect}"

  EventMachine.start_server socket_host, socket_port+1, Messages::MonitorSession
  EventMachine.start_server socket_host, socket_port, Messages::DroneSession
  Messages::PeriodicTimer.start

  inform "Messages now running"

  Signal.trap("INT") {
    Messages.shutdown("Received interrupt signal")
  }
  Signal.trap("TERM") {
    Messages.shutdown("Received termination signal")
  }

  EM.error_handler(Messages.error_handler)
}
