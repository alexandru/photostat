module Photostat
  class Flickr < Plugins::Base
    include OSUtils

    help_text "Manages your Flickr account"
    exposes :config, "Configures Flickr login"

    def activate!
      # authenticating to Flickr
      require 'flickraw'

      @config = YAML::load File.read(File.expand_path "~/.photostat")
      FlickRaw.api_key = @config[:flickr][:api_key]
      FlickRaw.shared_secret = @config[:flickr][:shared_secret]

      flickr.access_token = @config[:flickr][:access_token]
      flickr.access_secret = @config[:flickr][:access_secret]

      begin
        login = flickr.test.login
      rescue FlickRaw::FailedResponse => e
        STDERR.puts "ERROR: Flickr Authentication failed : #{e.msg}"
        exit 1
      end      
    end

    def config
      puts
      config_file = File.expand_path "~/.photostat"

      unless File.exists? config_file
        Photostat.configure_plugin! :local
      end

      config = YAML::load(File.read config_file) 

      config[:flickr] ||= {
        :api_key => nil,
        :shared_secret => nil
      }

      puts "Configuring Flickr!"
      puts "-------------------"
      puts
      puts "You need to create an app to access your account, see:"
      puts "       http://www.flickr.com/services/apps/create/apply/"
      puts "Or if you already have an app key available, find it here:"
      puts "       http://www.flickr.com/services/apps/"
      puts 

      config[:flickr][:api_key] = input("Flickr Authentication :: Api Key",
          :default => config[:flickr][:api_key])
      config[:flickr][:shared_secret] = input("Flickr Authentication :: Shared Secret",
          :default => config[:flickr][:shared_secret])

      require 'flickraw'

      FlickRaw.api_key = config[:flickr][:api_key]
      FlickRaw.shared_secret = config[:flickr][:shared_secret]

      token = flickr.get_request_token
      auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')

      puts
      puts "Open this url in your process to complete the authication process:"
      puts "    " + auth_url

      verify = input("Copy here the number given when visiting the link above")
      begin
        flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
        login = flickr.test.login
        puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"        
      rescue FlickRaw::FailedResponse => e
        STDERR.puts "ERROR: Flickr Authentication failed : #{e.msg}"
        exit 1
      end

      config[:flickr][:access_token]  = flickr.access_token
      config[:flickr][:access_secret] = flickr.access_secret      

      File.open(config_file, 'w') do |fh|
        fh.write(YAML::dump(config))
        puts
        puts " >>>> modified ~/.photostat config"
        puts
      end  
    end
  end
end
