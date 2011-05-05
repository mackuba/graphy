module Graphy
  class Watch
    attr_accessor :name, :options

    def initialize(name, options = {})
      @name = name.to_s
      @options = options
    end

    def label
      (@options[:label] || @name).to_s
    end
  end

  class MonitoringSet
    attr_accessor :name, :type, :watches

    def initialize(name, options = {})
      @name = name.to_s
      @type = options[:type] || @name.to_sym
      @watches = []
      raise "Invalid monitor name: #{name}" if @name !~ /^[\w\-\.]+$/
    end

    def watch(name, options = {})
      @watches << Watch.new(name, options)
    end

    def monitor
      Graphy.monitors[@type]
    end

    def to_json
      %({"name": "#{name}", "unit": "#{monitor.unit}", "labels": #{watches.map(&:label).inspect}})
    end
  end

  class Config
    ROTATE_PERIODS = [:daily, :weekly, :monthly]

    def initialize(parent)
      @parent = parent
    end

    def schedule(string)
      @parent.schedule = string
    end

    def rotate(period)
      if ROTATE_PERIODS.include?(period)
        @parent.rotate_period = period
      else
        raise "Incorrect rotate period: #{period} (available options: #{ROTATE_PERIODS.join(', ')})"
      end
    end

    def keep(n)
      @parent.rotate_count = n
    end

    def add_monitor(*args)
      @parent.add_monitor(*args)
    end

    def monitor(name, options = {})
      set = MonitoringSet.new(name, options)
      if set.monitor
        @parent.monitoring_sets << set
        yield set
      else
        raise "Unknown monitor type: #{set.type}"
      end
    end
  end

  class << self
    attr_accessor :schedule, :monitoring_sets, :rotate_count, :rotate_period

    def set_defaults
      @monitoring_sets ||= []
      @rotate_period ||= :weekly
      @rotate_count ||= 4
      @schedule ||= "*/10 * * * *"
    end

    def configure
      set_defaults
      yield Config.new(self)
    end
  end
end
