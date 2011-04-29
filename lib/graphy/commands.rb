require 'graphy/graphy'
require 'graphy/meta'

program :version, Graphy::VERSION
program :description, Graphy::DESCRIPTION
program :help_formatter, :compact

program :help, "Instructions", %(
  1. Run 'graphy init' to setup files and directories (rerun this after each gem update).
  2. Edit #{Graphy::CONFIG_FILE}, set your schedule and list processes to monitor.
  3. Run 'graphy update' to enable monitoring (rerun this each time you modify the config file).
  4. Run 'graphy config nginx' and paste the output into your Nginx config.
  5. Access reports at http://your.server/graphy.)

default_command :help

command :init do |c|
  c.syntax = 'graphy init'
  c.summary = "Creates a directory for graphy in /var/lib/graphy and copies all necessary files"
  c.action { Graphy.init }
end

command :update do |c|
  c.syntax = 'graphy update'
  c.summary = "Updates crontab, your log files and logrotate config"
  c.action { Graphy.update }
end

alias_command :enable, :update

command :remove do |c|
  c.syntax = 'graphy remove'
  c.summary = "Removes the crontab line that runs graphy (leaves all files unchanged)"
  c.action { Graphy.disable }
end

alias_command :disable, :remove

command :purge do |c|
  c.syntax = 'graphy purge'
  c.summary = "Deletes all files created by graphy (including all generated logs)"
  c.action { Graphy.purge }
end

command :log do |c|
  c.syntax = 'graphy log'
  c.summary = "Adds one line to the CSV log file(s) (this is called automatically by cron)"
  c.action { Graphy.add_data_line }
end

command :server do |c|
  c.syntax = 'graphy server'
  c.summary = "Starts a Webrick server in the graphy data directory to serve the log report on http://localhost:8000"
  c.action { Graphy.start_server }
end

command 'config nginx' do |c|
  c.syntax = 'graphy config nginx'
  c.summary = "Prints config lines to be added to Nginx config file"
  c.action do
    puts %(
      location ~* ^\/graphy {
        root #{Graphy::NGINX_BASE_DIR};
      }
    )
  end
end
