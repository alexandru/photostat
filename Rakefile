require 'rake/gempackagetask'
require './lib/flickrcli'

PKG_FILES = FileList["lib/**/*.rb", "bin/*", "[A-Z]*", "test/**/*"]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Flickr Command-Line Utilities"
  s.name = 'flickrcli'
  s.version = FlickrCLI::VERSION

  s.author = "Alexandru Nedelcu"
  s.email = "me@alexn.org"

  s.executables = ["bin/flickr"]
  s.default_executable = "bin/flickr"

  s.requirements << 'Flickr account, with a Flickr API Key initialized'
  s.requirements << 'Lots of photos, offline or uploaded on Flickr'
  s.add_dependency 'flickraw', '>= 0.8.4'

  s.require_path = 'lib'
  s.files = PKG_FILES
  s.has_rdoc = false

  s.description = "FlickrCLI provides utilities for synchronizing with your Flickr account."
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

