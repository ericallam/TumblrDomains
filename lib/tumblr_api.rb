module TumblrApi
  mattr_accessor :handler

  class NullHandler
    def initialize(*args)
    end

    def tumblelogs
      []
    end

    def authorized?
      true
    end
  end

  class LiveHandler
    def initialize(username, password)
      @username = username
      @password = password
    end

    def tumblelogs
      user.tumblr['tumblelog']
    end

    def authorized?
      !!user.tumblr
    end

    private

    def user
      @user ||= Tumblr::User.new @username, @password
    end
  end

  def self.handler
    @handler ||= LiveHandler
  end
end
