require 'thin'
require 'rack'
require 'sinatra/base'
require 'photostat/webapp/lib/racks'

module Photostat
  module WebApp
    def self.root
      Pathname.new File.join(File.dirname(__FILE__), '..')
    end

    def self.start_server!
      config = Photostat.config
      my_app = Photostat::WebApp.app

      builder = Rack::Builder.new do
        map '/' do
          run Photostat::WebApp.app
        end

        map '/photos' do
          run Rack::Directory.new(config[:repository_path])
        end
      end

      Rack::Handler::Thin.run builder.to_app, :Port => 3000, :Host => "0.0.0.0"
    end

    def self.app
      code = File.read(root.join('lib', 'app.rb').to_s)     
      eval %Q{
        Photostat::WebApp::AppBase.class_eval do
          #{code}
        end
      }
      return Photostat::WebApp::AppBase
    end

    class AppBase < Sinatra::Base
      set :root, Photostat::WebApp.root.to_s
      set :public_folder, Photostat::WebApp.root.join('public').to_s
      set :environment, :development

      enable :static, :sessions, :show_exceptions
      disable :run
    end
  end
end
