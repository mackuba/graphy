#!/usr/bin/env ruby

require 'fileutils'
require 'commander/import'
require 'graphy/config'

module Graphy
  ROOT_DIR = ENV['GRAPHY_DIR'] || "/var/lib/graphy"
  TEMPLATE_DIR = File.expand_path(File.join(__FILE__, '..', '..', 'templates'))
  LOGROTATE_DIR = "/etc/logrotate.d"

  CONFIG_FILE_NAME = "graphy.conf"
  LOGROTATE_FILE_NAME = "graphy"
  STATIC_FILES = ["index.html", "graphy.js", "dygraph-combined.js"]
  FILES = STATIC_FILES + [CONFIG_FILE_NAME]

  CONFIG_FILE = File.join(ROOT_DIR, CONFIG_FILE_NAME)
  LOGROTATE_FILE = File.join(LOGROTATE_DIR, LOGROTATE_FILE_NAME)

  GRAPHY_CRONTAB_MARKER = "# graphy gem"

  CREATE = $terminal.color("  create", :green)
  UPDATE = $terminal.color("  update", :green)
  IGNORE = $terminal.color("  ignore", :yellow)
  REMOVE = $terminal.color("  remove", :red)

  class << self
    def init
      if File.directory?(LOGROTATE_DIR)
        copy_template("graphy.logrotate", :to => LOGROTATE_DIR, :as => LOGROTATE_FILE_NAME)
      else
        puts "Warning: #{LOGROTATE_DIR} doesn't exist - Graphy log files at #{ROOT_DIR}/*.csv won't be rotated."
      end

      create_root_directory
      STATIC_FILES.each { |f| copy_template(f) }

      if File.exist?(CONFIG_FILE)
        log IGNORE, CONFIG_FILE
      else
        copy_template(CONFIG_FILE_NAME)
      end

      if ::Process.euid == 0 && (username = ENV['SUDO_USER'])
        user_files = FILES.map { |f| user_file(f) }

        change_owner(username, [ROOT_DIR] + files)
        change_owner(username, LOGROTATE_FILE) if File.exist?(LOGROTATE_FILE)
      end
    end

    def update
      load_config

      if Graphy.schedule.nil?
        fail "No schedule - please update your graphy.conf."
      end

      crontab = load_crontab
      old_line = find_graphy_crontab_line(crontab)

      if old_line
        log UPDATE, "crontab entry"
        old_line.replace(graphy_crontab_line)
      else
        log CREATE, "crontab entry"
        crontab << graphy_crontab_line
      end

      save_crontab(crontab)
      update_logs
    end

    def disable
      crontab = load_crontab
      old_line = find_graphy_crontab_line(crontab)

      if old_line
        log REMOVE, "crontab entry"
        crontab.delete(old_line)
        save_crontab(crontab)
      end
    end

    def purge
      if File.directory?(ROOT_DIR) && ask("Deleting all data - are you sure? (y/n) ")
        Dir[ROOT_DIR + "/*"].each { |f| File.unlink(f) }
        Dir.rmdir(ROOT_DIR)
      end
    rescue SystemCallError
      sudo_fail "#{ROOT_DIR} can't be deleted"
    end

    def add_data_line
      load_config

      data = [Time.now.to_i]
      labels = ['time']

      Graphy.processes.each do |process|
        ps = `ps ax -o rss,command`
        sum = 0
        ps.each_line do |line|
          if line.include?(process.name)
            sum += line.strip.split(/\s+/)[0].to_i
          end
        end
        data << sum
        labels << process.name
      end

      csv = user_file("log.csv")
      existed = File.exist?(csv)

      File.open(csv, "a") do |f|
        f.puts(labels.join(",")) unless existed
        f.puts(data.join(","))
      end
    end

    def start_server
      # TODO: switch to something less shitty
      require 'webrick'
      server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => ROOT_DIR
      server.start
    end


    private

    def create_root_directory
      unless File.directory?(ROOT_DIR)
        log CREATE, ROOT_DIR
        Dir.mkdir(ROOT_DIR)
      end
    rescue SystemCallError
      sudo_fail "#{ROOT_DIR} can't be created"
    end

    def copy_template(name, options = {})
      directory = options[:to] || ROOT_DIR
      new_name = options[:as] || name
      path = File.join(directory, new_name)
      template = original_file(name)

      log CREATE, path
      File.open(path, "w") do |f|
        contents = File.read(template).gsub(/\#\{(\w+)\}/) { $1.constantize }
        f.write(contents)
      end
    rescue SystemCallError
      sudo_fail "#{path} can't be created"
    end

    def fail(problem)
      puts problem
      exit 1
    end

    def sudo_fail(problem)
      fail "#{problem} - run this command with 'sudo' or 'rvmsudo'."
    end

    def change_owner(username, files)
      uid = `id -u #{username}`.to_i
      gid = `id -g #{username}`.to_i
      files.each do |file|
        log "chown", file
        File.chown(uid, gid, file)
      end
    end

    def original_file(name)
      File.join(TEMPLATE_DIR, name)
    end

    def user_file(name)
      File.join(ROOT_DIR, name)
    end

    def load_crontab
      `crontab -l 2> /dev/null`.split(/\n/)
    end

    def save_crontab(crontab)
      crontab_file = user_file("crontab")
      File.open(crontab_file, "w") do |file|
        crontab.each do |line|
          file.puts(line)
        end
      end

      system("crontab #{crontab_file}")
      File.unlink(crontab_file)
    end

    def find_graphy_crontab_line(crontab)
      crontab.detect { |l| l.include?(GRAPHY_CRONTAB_MARKER) }
    end

    def graphy_crontab_line
      rvm_path = ENV['rvm_path']
      rvm_load = "source #{rvm_path}/scripts/rvm &&" if rvm_path

      "#{Graphy.schedule}     #{rvm_load} graphy log   #{GRAPHY_CRONTAB_MARKER}"
    end

    def load_config
      if File.exist?(CONFIG_FILE)
        load CONFIG_FILE
      else
        fail "No #{CONFIG_FILE_NAME} file - please run 'graphy install'."
      end
    end

    def update_logs
      # TODO: update logs instead of deleting them
      Dir[ROOT_DIR + "/log.csv*"].each { |f| File.unlink(f) }
    end
  end
end
