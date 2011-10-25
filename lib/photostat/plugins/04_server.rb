module Photostat
  class Server < Plugins::Base
    help_text "Web Interface for local management of photos"

    exposes :run, 'starts web application'

    def run
      opts = Trollop::options do; end

      require 'photostat/webapp/lib/server'
      Photostat::DB.migrate!
      Photostat::WebApp.start_server!
    end
  end
end
