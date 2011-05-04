module Graphy
  class Monitor
    attr_accessor :name, :unit

    def initialize(name, unit, block)
      @name = name
      @unit = unit
      @block = block
    end

    def call(watch, set)
      @block.call(watch, set)
    end
  end

  class << self
    def monitors
      @monitors ||= {}
    end

    #
    # usage:
    #
    # Graphy.add_monitor(:disk_space, 'MB') do |watch, set|
    #   result = `du -sm #{watch.name}`
    #   result.split(/\s+/).first.to_i
    # end
    #
    # and then, in the config file:
    #
    # g.monitor :disk_space do |m|
    #   m.watch "/var/lib/mongodb", :label => "MongoDB"
    #   m.watch "/var/www/foo/shared/public", :label => "Uploaded files"
    # end
    #

    def add_monitor(name, unit, proc = nil, &block)
      monitors[name] = Monitor.new(name, unit, proc || block)
    end

    def process_filter_monitor(ps_field, divisor = nil)
      Proc.new do |watch, set|
        ps = `ps ax -o #{ps_field},command`
        sum = 0
        ps.each_line do |line|
          if line.include?(watch.name)
            value = line.strip.split(/\s+/).first.to_f
            value /= divisor if divisor
            sum += value
          end
        end
        divisor ? sprintf("%.1f", sum) : sum.to_i
      end
    end
  end

  add_monitor :memory, ' MB', process_filter_monitor('rss', 1000)
  add_monitor :cpu, '%', process_filter_monitor('pcpu')
end
