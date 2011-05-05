#!/usr/bin/env ruby

require 'fileutils'
require 'commander/import'
require 'graphy/config'
require 'graphy/monitors'

module Graphy
  ROOT_DIR = ENV['GRAPHY_DIR'] || "/var/lib/graphy"
  TEMPLATE_DIR = File.expand_path(File.join(__FILE__, '..', '..', 'templates'))
  LOGROTATE_DIR = "/etc/logrotate.d"
  NGINX_BASE_DIR = ROOT_DIR.chomp('/').split('/').slice(0..-2).join('/')

  CONFIG_FILE_NAME = "graphy.conf"
  LOGROTATE_FILE_NAME = "graphy"
  ASSET_FILES = ["index.html", "graphy.js", "dygraph-combined.js"]
  ALL_FILES = ASSET_FILES + [CONFIG_FILE_NAME]

  CONFIG_FILE = File.join(ROOT_DIR, CONFIG_FILE_NAME)
  LOGROTATE_FILE = File.join(LOGROTATE_DIR, LOGROTATE_FILE_NAME)

  GRAPHY_CRONTAB_MARKER = "# graphy gem"

  LOG_COLORS = {
    :create => :green,
    :update => :green,
    :ignore => :yellow,
    :remove => :red
  }

  class << self
    def init
      if File.directory?(LOGROTATE_DIR)
        copy_template("graphy.logrotate", :to => LOGROTATE_DIR, :as => LOGROTATE_FILE_NAME)
      else
        log "Warning: #{LOGROTATE_DIR} doesn't exist - Graphy log files at #{ROOT_DIR}/*.csv won't be rotated."
      end

      create_root_directory

      if File.exist?(CONFIG_FILE)
        log :ignore, CONFIG_FILE
      else
        copy_template(CONFIG_FILE_NAME)
      end

      if Process.euid == 0 && (username = ENV['SUDO_USER'])
        change_owner(username, ROOT_DIR, CONFIG_FILE)
        change_owner(username, LOGROTATE_FILE) if File.exist?(LOGROTATE_FILE)
      end
    end

    def update
      load_config

      if File.directory?(LOGROTATE_DIR)
        copy_template("graphy.logrotate", :to => LOGROTATE_DIR, :as => LOGROTATE_FILE_NAME)
      else
        log :ignore, LOGROTATE_DIR
      end

      ASSET_FILES.each { |f| copy_template(f) }

      crontab = load_crontab
      old_line = find_graphy_crontab_line(crontab)

      # disable crontab to make sure it doesn't add a line logs while we're updating them
      if old_line
        crontab.delete(old_line)
        save_crontab(crontab)
        updated = true
      end

      update_logs

      log(updated ? :update : :create, "crontab entry")
      crontab << graphy_crontab_line
      save_crontab(crontab)
    end

    def disable
      crontab = load_crontab
      old_line = find_graphy_crontab_line(crontab)

      if old_line
        log :remove, "crontab entry"
        crontab.delete(old_line)
        save_crontab(crontab)
      end
    end

    def purge
      if ask("Deleting all data - are you sure? (y/n) ")
        if File.directory?(ROOT_DIR)
          Dir[ROOT_DIR + "/*"].each do |f|
            log :remove, f
            File.unlink(f)
          end
          log :remove, ROOT_DIR
          Dir.rmdir(ROOT_DIR)
        end

        if File.exist?(LOGROTATE_FILE)
          log :remove, LOGROTATE_FILE
          File.unlink(LOGROTATE_FILE)
        end
      end
    rescue SystemCallError
      sudo_fail "#{ROOT_DIR} can't be deleted"
    end

    def add_data_line
      load_config

      Graphy.monitoring_sets.each do |set|
        data = [Time.now.to_i]
        labels = ['time']

        set.watches.each do |watch|
          data << set.monitor.call(watch, set)
          labels << watch.name
        end

        csv = user_file("#{set.name}.csv")
        existed = File.exist?(csv)

        if existed && File.mtime(CONFIG_FILE) > File.mtime(csv)
          log "Error: #{csv} wasn't updated after a config modification, please run 'graphy update'."
          return
        end

        File.open(csv, "a") do |f|
          f.puts(labels.join(",")) unless existed
          f.puts(data.join(","))
        end
      end
    end

    def start_server
      require 'webrick'

      # fixes a conflict between Webrick and Rack that prevents Webrick from closing when CTRL-C is pressed
      ['INT', 'TERM'].each do |signal|
        Signal.trap(signal) { exit!(0) }
      end

      server = WEBrick::HTTPServer.new :Port => 8444, :DocumentRoot => ROOT_DIR
      server.start
    end


    private

    def create_root_directory
      unless File.directory?(ROOT_DIR)
        log :create, ROOT_DIR
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

      log :create, path
      File.open(path, "w") do |f|
        contents = if String.new.respond_to?(:encoding)
          File.read(template, :external_encoding => 'UTF-8')
        else
          File.read(template)
        end
        contents.gsub!(/\{\{(.+?)\}\}/) { eval $1 }
        f.write(contents)
      end
    rescue SystemCallError
      sudo_fail "#{path} can't be created"
    end

    def fail(problem)
      log problem
      exit 1
    end

    def sudo_fail(problem)
      fail "#{problem} - run this command with 'sudo' or 'rvmsudo'."
    end

    def log(type, message = nil)
      if message
        color = LOG_COLORS[type]
        label = color ? $terminal.color(type, color, :bold) : type
        pad = " " * (12 - type.to_s.length)
        say("#{pad}#{label}  #{message}")
      else
        puts type
      end
    end

    def change_owner(username, *files)
      uid = `id -u #{username}`.to_i
      gid = `id -g #{username}`.to_i
      files.each do |file|
        log :chown, file
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

      "#{Graphy.schedule}     /bin/bash -c \"#{rvm_load} graphy log\"   #{GRAPHY_CRONTAB_MARKER}"
    end

    def load_config
      if File.exist?(CONFIG_FILE)
        load CONFIG_FILE
      else
        fail "No #{CONFIG_FILE_NAME} file - please run 'graphy install'."
      end
    end

    def update_logs
      Graphy.monitoring_sets.each do |set|
        csv = user_file("#{set.name}.csv")
        if File.exist?(csv)
          update_log(csv, set.watches.map(&:name))
        else
          log :ignore, csv
        end
      end
    end

    def update_log(filename, new_labels)
      data = File.read(filename)

      old_labels = data.lines.first.strip.split(/,/)
      new_labels = ['time'] + new_labels

      if old_labels == new_labels
        log :ignore, filename
        FileUtils.touch(filename)
        return
      else
        log :update, filename
      end

      columns_to_add = new_labels - old_labels
      columns_to_remove = old_labels - new_labels

      log "\tColumns added: #{columns_to_add.inspect}" unless columns_to_add.empty?
      log "\tColumns removed: #{columns_to_remove.inspect}" unless columns_to_remove.empty?

      old_indexes = new_labels.map { |label| old_labels.index(label) }

      File.open(filename, "w") do |file|
        file.puts(new_labels.join(','))

        data.lines.to_a.slice(1..-1).each do |line|
          old_values = line.strip.split(/,/)
          new_values = old_indexes.map { |i| i ? old_values[i] : 0 }
          file.puts(new_values.join(','))
        end
      end
    end

  end
end
