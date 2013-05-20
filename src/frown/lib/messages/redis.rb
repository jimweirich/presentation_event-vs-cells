module Messages
  module Redis
    def redis
      Messages::Redis.server
    end

    def self.server
      @server
    end

    def self.server=(redis_server)
      @server = redis_server
    end
  end
end
