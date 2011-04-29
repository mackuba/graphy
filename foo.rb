#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'Foo'

program :version, Foo::VERSION
program :description, 'Foo Bar'
 
command :one do |c|
  c.syntax = 'Foo one [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Foo::Commands::One
  end
end

command :two do |c|
  c.syntax = 'Foo two [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Foo::Commands::Two
  end
end

command :three do |c|
  c.syntax = 'Foo three [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Foo::Commands::Three
  end
end

