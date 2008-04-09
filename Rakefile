require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'rake/runtest'

PROJECT_NAME = 'midilib'
RUBYFORGE_USER = 'jimm'
RDOC_DIR = 'html'

PKG_FILES = FileList[ 'ChangeLog', 'Credits', 'README', 'Rakefile', 'TODO',
    'examples/**/*',
    'html/**/*',
    'install.rb',
    'lib/**/*.rb',
    'test/**/*']

task :default => [:package]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.name = PROJECT_NAME
    s.version = `ruby -Ilib -e 'require "midilib/info"; puts MIDI::Version'`.strip
    s.requirements << 'none'

    s.require_path = 'lib'
    s.autorequire = PROJECT_NAME

    s.files = PKG_FILES.to_a

    s.has_rdoc = true
    s.rdoc_options << '--main' << 'README'
    s.extra_rdoc_files = ['README', 'TODO']

    s.author = 'Jim Menard'
    s.email = 'jimm@io.com'
    s.homepage = 'http://midilib.rubyforge.org'
    s.rubyforge_project = PROJECT_NAME

    s.summary = "MIDI file and event manipulation library"
    s.description = <<EOF
midilib is a pure Ruby MIDI library useful for reading and
writing standard MIDI files and manipulating MIDI event data.
EOF
end

# Creates a :package task (also named :gem). Also useful are :clobber_package
# and :repackage.
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
end

# creates an "rdoc" task
Rake::RDocTask.new do | rd |
    rd.main = 'README'
    rd.title = PROJECT_NAME
    rd.rdoc_files.include('README', 'TODO', 'lib/**/*.rb')
end

task :rubyforge => [:rdoc] do
    Rake::RubyForgePublisher.new(PROJECT_NAME, RUBYFORGE_USER).upload
end

task :test do
    Rake::run_tests
end
