require "fileutils"
require "optparse"
require 'yaml'
require 'flickraw'

module FlickrCLI
  class << self
    def oror(a, b)
      return a && a != '' ? a : b
    end

    def get_config_options
      conf_file = ENV['HOME'] + "/.flickr-cli/config"
      YAML::load_file(conf_file)
    rescue
      {:app => {}, :user => {}}
    end

    def run
      home_dir = ENV['HOME']
      old_options = get_config_options
      options = {}

      old_val = old_options[:api_key] || old_options[:app][:api_key]
      $stdout.write "Flickr Key (#{old_val}): "
      options[:app] = {:api_key => oror($stdin.readline.strip, old_val)}

      old_val = old_options[:shared_secret] || old_options[:app][:shared_secret]
      $stdout.write "Flickr Secret (#{old_val}): "
      options[:app][:shared_secret] = oror($stdin.readline.strip, old_val)

      FlickRaw.api_key = options[:app][:api_key]
      FlickRaw.shared_secret = options[:app][:shared_secret]

      frob = flickr.auth.getFrob
      auth_url = FlickRaw.auth_url :frob => frob, :perms => 'delete'

      puts
      puts "Open this url in your browser to complete the authentication process : #{auth_url}"
      puts "Press Enter when you are finished.\n"
      STDIN.getc

      begin
        auth = flickr.auth.getToken :frob => frob
        login = flickr.test.login
        puts "You are now authenticated as #{login.username} with token #{auth.token}"
      rescue FlickRaw::FailedResponse => e
        puts "Authentication failed : #{e.msg}"
        exit
      end

      options[:user] = {:auth_token => auth.token}

      if not File.directory? "#{home_dir}/.flickr-cli"
        Dir.mkdir "#{home_dir}/.flickr-cli"
      end

      File.open("#{home_dir}/.flickr-cli/config", "w") do |f|
        f.write(options.to_yaml)
      end
    end
  end
end


if __FILE__ == $0
  FlickrCLI::run
end
