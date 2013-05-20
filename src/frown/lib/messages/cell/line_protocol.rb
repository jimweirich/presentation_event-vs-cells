class LineProtocol
  def initialize(socket)
    @socket = socket
    @buffer = ''
    @buffer.force_encoding('BINARY')
  end

  def gets
    line = nil
    rest = nil
    loop do
      line, rest = @buffer.split(/\n/,2)
      break if rest
      @buffer << read_socket
    end
    @buffer = rest
    line + "\n"
  end

  def puts(str)
    str += "\n" unless str =~ /\n\Z/
    @socket.write(str)
  end

  def read_socket
    result = @socket.readpartial(4096)
    result.force_encoding('BINARY')
    result
  end

end
