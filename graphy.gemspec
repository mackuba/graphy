lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'graphy/meta'

Gem::Specification.new do |s|
  s.name = "graphy"
  s.version = Graphy::VERSION
  s.summary = Graphy::DESCRIPTION
  s.homepage = "http://github.com/psionides/graphy"

  s.author = "Jakub Suder"
  s.email = "jakub.suder@gmail.com"

  s.files = ['MIT-LICENSE', 'README.markdown', 'Changelog.markdown', 'Gemfile', 'Gemfile.lock'] + Dir['lib/**/*']

  s.add_dependency 'commander', '~> 4.0'
end
