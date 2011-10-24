# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "photostat/version"

Gem::Specification.new do |s|
  s.name        = "photostat"
  s.version     = Photostat::VERSION
  s.authors     = ["Alexandru Nedelcu"]
  s.email       = ["me@alexn.org"]
  s.homepage    = "http://github.com/alexandru/photostat"
  s.summary     = %q{Managing Photos for Hackers}
  s.description = %q{Photostat is a collection of command-line utilities for managing photos / syncronizing with Flickr.}

  s.rubyforge_project = "photostat"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler"

  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency 'sqlite3'
  s.add_runtime_dependency 'activerecord', '3.1.0'
  s.add_runtime_dependency "trollop"
  s.add_runtime_dependency "escape"
  s.add_runtime_dependency "flickraw"
  s.add_runtime_dependency "exifr"
  s.add_runtime_dependency "escape"
  s.add_runtime_dependency "json"
end
