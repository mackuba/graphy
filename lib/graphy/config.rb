module Graphy
  class Process
    attr_accessor :name, :options

    def initialize(name, options = {})
      @name = name.to_s
      @options = options
    end
  end

  class Config
    def initialize(parent)
      @parent = parent
    end

    def schedule(string)
      @parent.schedule = string
    end

    def process(name, options = {})
      @parent.processes << Process.new(name, options)
    end
  end

  class << self
    attr_accessor :schedule, :processes

    def processes
      @processes ||= []
    end

    def configure
      yield Config.new(self)
    end
  end
end
