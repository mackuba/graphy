module Graphy
  class Monitor
    attr_accessor :name, :unit

    def initialize(name, unit, block)
      @name = name
      @unit = unit
      @block = block
    end

    def call(process, set)
      @block.call(process, set)
    end
  end

  class << self
    def monitors
      @monitors ||= {}
    end

    def add_monitor(name, unit, proc = nil, &block)
      monitors[name] = Monitor.new(name, unit, proc || block)
    end

    def process_filter_monitor(ps_field, divisor = nil)
      Proc.new do |process, set|
        ps = `ps ax -o #{ps_field},command`
        sum = 0
        ps.each_line do |line|
          if line.include?(process.name)
            value = line.strip.split(/\s+/).first.to_i
            value = value.to_f / divisor if divisor
            sum += value
          end
        end
        divisor ? sprintf("%.1f", sum) : sum
      end
    end
  end

  add_monitor :memory, 'M', process_filter_monitor('rss', 1000)
  add_monitor :cpu, '%', process_filter_monitor('pcpu')
end
