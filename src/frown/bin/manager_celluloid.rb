ENV['PATH'] = ENV['PATH'] + ":/usr/sbin"
require 'celluloid/io'
require 'messages/cell/drone_cell'
require 'messages/cell/monitor_cell'

class DroneCelluloid

  DRONES = {}

  def run
    monitor = MonitorCell.new("0.0.0.0", 8091)
    drones = DroneCell.new(monitor, "0.0.0.0", 8090)
    monitor.drones = drones
  end
end

main = DroneCelluloid.new
main.run
sleep
