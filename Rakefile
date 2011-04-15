require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'
require './lib/photostat'

PKG_FILES = FileList["lib/**/*.rb", "bin/*", "[A-Z]*", "test/**/*"]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Photostat - Command-Line Utilities For Keeping a Photo-Collection"
  s.name = 'photostat'
  s.version = Photostat::VERSION
  s.rubyforge_project = "photostat"

  s.author = "Alexandru Nedelcu"
  s.email = "me@alexn.org"
  s.homepage = "https://github.com/alexandru/photostat"
  s.executables = ["photostat"]
  s.default_executable = "photostat"

  s.required_ruby_version = ">= 1.9.1"

  s.requirements << 'Flickr account, with a Flickr API Key initialized, in case you want Flickr synchronization'
  s.requirements << 'Lots of photos, offline or uploaded on Flickr'
  s.add_dependency 'flickraw', '>= 0.8.4'

  s.require_path = 'lib'
  s.files = PKG_FILES
  s.has_rdoc = true

  s.description = "Photostat provides utilities for building a local photo repository + synchronizing with your Flickr account."
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => [:test_units]
task :test    => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test_units") { |t|
  t.pattern = 'test/*_test.rb'
  t.verbose = true
  t.warning = true
}

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end
