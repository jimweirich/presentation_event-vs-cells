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

BINDIR = File.dirname($0)
HOMEDIR = File.dirname(BINDIR)

inform "Drone Manager"

SOCKET_MAX = 5000

max_files = EventMachine.set_descriptor_table_size
if (max_files < SOCKET_MAX)
  inform "File descriptor table size #{max_files} limits max# sockets, attempting change to #{SOCKET_MAX}"
  max_files = EventMachine.set_descriptor_table_size(SOCKET_MAX)
end
inform "File descriptor table size is now #{max_files}"

EventMachine.epoll

EventMachine.run {
  socket_host = "0.0.0.0"
  socket_port = 8090
  inform "Server Address #{socket_host} on port #{socket_port}"

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
