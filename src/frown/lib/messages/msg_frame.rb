module Messages
  class MsgFrame
    def self.decode(str)
      str.strip.gsub(/[^ -~]/,'')
    end

    def self.encode(str)
      str + "\n"
    end
  end
end
