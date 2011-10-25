#!/usr/bin/env ruby

require 'thin'
require 'rack'

app = Rack::Builder.new {
  run Rack::Cascade.new([
    Rack::Directory.new("/home/alex/Pictures/")
  ])
}.to_app

Rack::Handler::Thin.run app, :Port => 3000, :Host => "0.0.0.0"
