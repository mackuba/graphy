module Graphy
  class << self
    def monitors
      @monitors ||= {}
    end

    def add_monitor(name, proc = nil, &block)
      monitors[name] = proc || block
    end

    def process_filter_monitor(ps_field)
      Proc.new do |process, set|
        ps = `ps ax -o #{ps_field},command`
        sum = 0
        ps.each_line do |line|
          if line.include?(process.name)
            sum += line.strip.split(/\s+/).first.to_i
          end
        end
        sum
      end
    end
  end

  add_monitor :memory, process_filter_monitor('rss')
  add_monitor :cpu, process_filter_monitor('pcpu')
end
