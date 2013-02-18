lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'graphy/meta'

Gem::Specification.new do |s|
  s.name = "graphy"
  s.version = Graphy::VERSION
  s.summary = Graphy::DESCRIPTION
  s.homepage = "http://github.com/jsuder/graphy"

  s.author = "Jakub Suder"
  s.email = "jakub.suder@gmail.com"

  s.files = [
    'MIT-LICENSE', 'README.markdown', 'Changelog.markdown', 'Gemfile', 'Gemfile.lock'
  ] + Dir['lib/**/*'] + Dir['spec/**/*']

  s.executables = ['graphy']

  s.add_dependency 'commander', '~> 4.0'

  s.add_development_dependency 'rspec', '~> 2.5'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'json'
end
