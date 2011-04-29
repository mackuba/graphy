lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

Gem::Specification.new do |s|
  s.name = "graphy"
  s.version = "0.1"
  s.summary = "Easy way to generate CPU and memory graphs for your server"
  s.homepage = "http://github.com/psionides/graphy"

  s.author = "Jakub Suder"
  s.email = "jakub.suder@gmail.com"

  s.files = ['MIT-LICENSE', 'README.markdown', 'Changelog.markdown', 'Gemfile', 'Gemfile.lock'] + Dir['lib/**/*']
end
