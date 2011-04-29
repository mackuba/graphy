#!/usr/bin/env ruby

require 'fileutils'

ROOT_DIR = ENV['GRAPHY_DIR'] || "/var/lib/graphy"
TEMPLATE_DIR = File.expand_path(File.join(__FILE__, '..', '..', 'templates'))
FILES = ["graphy.conf", "index.html", "graphy.js", "dygraph-combined.js"]

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

case ARGV.first
  when "install"
    begin
      if File.directory?("/etc/logrotate.d")
        File.open("/etc/logrotate.d/graphy", "w") do |f|
          logrotate = File.read(File.join(TEMPLATE_DIR, "graphy.logrotate")).gsub(/%ROOT_DIR%/, ROOT_DIR)
          f.write(logrotate)
        end
      else
        puts "Warning: /etc/logrotate.d doesn't exist - Graphy log files at #{ROOT_DIR}/*.csv won't be rotated."
      end
    rescue SystemCallError
      puts "/etc/logrotate.d/graphy can't be created - run this command with 'sudo' or 'rvmsudo'"
      exit 1
    end

    begin
      Dir.mkdir(ROOT_DIR) unless File.directory?(ROOT_DIR)
    rescue SystemCallError
      puts "#{ROOT_DIR} can't be created - run this command with 'sudo' or 'rvmsudo'"
      exit 1
    end

    # ask to overwrite
    (FILES - ["graphy.conf"]).each { |f| FileUtils.cp(File.join(TEMPLATE_DIR, f), ROOT_DIR) }

    if File.exist?(File.join(ROOT_DIR, "graphy.conf"))
      puts "#{File.join(ROOT_DIR, "graphy.conf")} already exists - delete it and try again if you want to recreate it."
    else
      FileUtile.cp(File.join(TEMPLATE_DIR, "graphy.conf"), ROOT_DIR)
    end

    if Process.euid == 0
      real_user = ENV['SUDO_USER']
      if real_user
        uid = `id -u #{real_user}`.to_i
        gid = `id -g #{real_user}`.to_i
        files = FILES.map { |f| File.join(ROOT_DIR, f) }
        File.chown(uid, gid, ROOT_DIR, *files)
        File.chown(uid, gid, "/etc/logrotate.d/graphy") if File.exist?("/etc/logrotate.d/graphy")
      end
    end

  when "log"
    unless File.exist?(File.join(ROOT_DIR, "graphy.conf"))
      puts "No graphy.conf file - please run install."
      exit 1
    end

    load File.join(ROOT_DIR, "graphy.conf")

    data = []

    data << Time.now.to_i

    # memory_stats = `free -k -o | grep Mem`
    # data << memory_stats.strip.split(/\s+/)[2].to_i

    Graphy.processes.each do |process|
      ps = `ps ax -o rss,command`
      sum = 0
      ps.each_line do |line|
        if line.include?(process.name)
          sum += line.strip.split(/\s+/)[0].to_i
        end
      end
      data << sum
    end

    csv = File.join(ROOT_DIR, "log.csv")
    existed = File.exist?(csv)

    File.open(csv, "a") do |f|
      f.write("time," + Graphy.processes.map(&:name).join(",") + "\n") unless existed
      f.write(data.join(",") + "\n")
    end

  when "update"
    # update csv
    # update index / js

    unless File.exist?(File.join(ROOT_DIR, "graphy.conf"))
      puts "No graphy.conf file - please run install."
      exit 1
    end

    load File.join(ROOT_DIR, "graphy.conf")

    unless Graphy.schedule
      puts "No schedule - please update your graphy.conf."
      exit 1
    end

    crontab = `crontab -l 2> /dev/null`.split(/\n/)
    old_line = crontab.grep(/# graphy gem/).first
    rvm_path = ENV['rvm_path']
    rvm_load = "source #{rvm_path}/scripts/rvm &&" if rvm_path
    new_line = "#{Graphy.schedule}     #{rvm_load} graphy log   # graphy gem"

    if old_line
      old_line.replace(new_line)
    else
      crontab << new_line
    end

    crontab_file = File.join(ROOT_DIR, "crontab")
    File.open(crontab_file, "w") { |f| f.write(crontab.map { |l| l + "\n" }.join) }
    system("crontab #{crontab_file}")
    File.unlink(crontab_file)

    # update logs
    Dir[ROOT_DIR + "/log.csv*"].each { |f| File.unlink(f) }

  when "remove"
    crontab = `crontab -l 2> /dev/null`.split(/\n/)
    old_line = crontab.grep(/# graphy gem/).first

    if old_line
      crontab.delete(old_line)
      crontab_file = File.join(ROOT_DIR, "crontab")
      File.open(crontab_file, "w") { |f| f.write(crontab.map { |l| l + "\n" }.join) }
      system("crontab #{crontab_file}")
      File.unlink(crontab_file)
    end

  when "server"
    require 'webrick'
    server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => ROOT_DIR
    server.start

  when "purge"
    begin
      if File.directory?(ROOT_DIR)
        print "Deleting all data - are you sure? (y/n) "
        if STDIN.gets.strip == "y"
          Dir[ROOT_DIR + "/*"].each { |f| File.unlink(f) }
          Dir.rmdir(ROOT_DIR)
        end
      end
    rescue SystemCallError => e
      puts "#{ROOT_DIR} can't be deleted - run this command with 'sudo' or 'rvmsudo'"
      exit 1
    end

  else
    puts "#{$0} log|server|install"
end
