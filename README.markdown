# Graphy

**Graphy** is a Ruby script that monitors things like memory or CPU usage on your server and generates reports with
graphs that show how those values changed over time. It's quite flexible, but really easy to install and set up.

## Idea

The general idea is that there's a task which is run by cron every few minutes that adds a line of data to one or more
CSV files. There's one CSV file for each "*monitoring set*", which is an aspect of the system that you want to monitor
(e.g. CPU usage or memory usage), and each column in a CSV file represents one monitored process. The log files are
rotated using logrotate – memory.csv becomes memory.csv.1, memory.csv.2, etc. By default this happens every week on
Sunday, and data from last 4 weeks is kept.

The columns in CSV files will usually represent process types, but they could represent other things, e.g. you could
set up a monitor to check disk space used by several important directories on the server. You can define custom monitor
types if the defaults (:cpu and :memory) aren't enough.

The data is then displayed using an HTML page which includes some Javascripts that load the CSV files through XHR
requests and use the data to generate graphs, which look like this:

<a href="https://github.com/jsuder/graphy/raw/82f070991898/graphy_example.png"><img src="https://github.com/jsuder/graphy/raw/82f070991898/graphy_example.png" width="880"></a>

## Installation

First, install the gem on your server:

    gem install graphy --pre

Then run the `init` command to initialize the required directories and files:

    sudo graphy init    # or rvmsudo if you use rvm

This will create a logrotate config for graphy at `/etc/logrotate.d/graphy` and a directory for storing config and data
files at `/var/lib/graphy`. You need to run this command through sudo, because a standard user probably doesn't have
write access to `/etc` and `/var/lib`.

If you want, you can set a custom path instead of the standard `/var/lib/graphy` with the environment variable
`GRAPHY_DIR` (note: with rvmsudo, you might need to call `rvmsudo GRAPHY_DIR=... graphy init`, variables set earlier
don't seem to be passed – this might depend on your RVM version though).

## Configuration

The `init` command will create a sample config file for you at `/var/lib/graphy/graphy.conf`. In the first part of the file, you can configure how often the data is logged to log files and how often the log files are rotated:

    Graphy.configure do |g|
      # crontab schedule:  minute hour day-of-month month day-of-week
      # default = "*/10 * * * *" (every 10 minutes)

      g.schedule "*/10 * * * *"

      # how often log files should be rotated (:daily/:weekly/:monthly)
      # and how many of them should be kept
      # default = 4 weekly logs

      g.rotate :weekly
      g.keep 4

The next part describes what you want to monitor. You can define several monitoring sets, each with a list of processes
that you want to check:

    g.monitor :cpu do |m|
      m.watch "nginx"
      m.watch "mongodb"
    end

    g.monitor :memory do |m|
      m.watch "nginx"
      m.watch "mongodb"
      m.watch "redis"
      m.watch "Rack", :label => "Rails instances"
    end

The string passed to `watch` is a name of the process as it appears in `ps` output. If you want to display the process
differently in the report, use the `:label` option.

Note: the line only needs to *include* the string, so an entry named "g" would match both "mongodb" and "nginx", and a
few other things. The value written to the log file will be the sum of values from all matching lines, so if you have 5
Rack processes, it will write down how much memory they take together.

If you want to have more than one monitoring set of the same kind, use the `:type` option:

    g.monitor :system_processes, :type => :memory do |m|
      m.watch "sshd"
      m.watch "ntpd"
      m.watch "cron"
    end

## Starting the monitor

When you're done updating the config file, you need to run one last command – `update` – to update some of the asset
files and add a line to crontab that will run `graphy log`:

    graphy update    # or: graphy enable

You need to remember to run this again every time you modify the config file, or after you update the gem to a new
version. This will also update any existing log files so that the columns match the new headers (warning: if you've
removed or even renamed a `watch` entry in the config file, this will delete all values collected for that watch from
your log files; newly added columns are filled with 0s).

## Accessing the reports

To see the reports in your browser, you need to share graphy's directory using a HTTP server. If you use Nginx, call
this command:

    graphy config nginx

It will show you the config lines that you need to add to Nginx to see the reports at `http://your.server/graphy` (feel
free to tweak it to change the path, protect it with password, etc.).

If you use Apache or some other web server, you need to figure something out :)

If you don't have any web server at hand, you can use this command:

    graphy server

This will start a Webrick server sharing graphy's directory at `http://localhost:8444`. You'll have to make it run in
the background though and perhaps make sure that it starts automatically on reboot and so on, so you're better off with
a real web server.

## Stopping the monitor

If for some reason you want to stop the monitoring, call:

    graphy remove    # or: graphy disable

This will remove the crontab line (and leave all your data in place).

## Deleting the data

If you want to completely remove whatever graphy has installed on the server, call the `purge` command:

    sudo graphy purge    # or rvmsudo

This will delete the logrotate config file and entire `/var/lib/graphy` directory.

## Custom monitors

If you need to monitor something else apart from memory and CPU usage, you can define a custom monitor type. For
example, you could define a monitor that checks disk space usage in given directories:

    g.add_monitor :disk_space, 'MB' do |watch, set|
      result = `du -sm #{watch.name}`
      result.split(/\s+/).first.to_i
    end

The arguments to `add_monitor` are the monitor's name and the unit displayed on the graph, and the arguments passed to
the block are the `watch` record (e.g. representing a process, or like here – a directory) and the monitoring set that
contains the watch line.

Then you could use your custom monitor like this:

    g.monitor :disk_space do |m|
      m.watch "/var/lib/mongodb", :label => "MongoDB"
      m.watch "/var/www/foo/shared/public", :label => "Uploaded files"
    end

## Credits

Graphy was created by [Jakub Suder](http://psionides.eu) at [Lunar Logic Polska](http://lunarlogicpolska.com). It's
licensed under [MIT license](https://github.com/psionides/graphy/blob/master/MIT-LICENSE.txt).

Graphy includes the following libraries (all MIT-licensed):

* [Dygraphs](http://dygraphs.com) by Dan Vanderkam for drawing graphs
* [Sammy.js](http://sammyjs.org) by Aaron Quint for navigation
* [jQuery](http://jquery.com)
