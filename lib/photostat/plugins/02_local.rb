module Photostat

  class Local < Plugins::Base
    include OSUtils
    help_text "Manages your local photos repository"

    exposes :config, "Configures your local database, repository path and Flickr login"
    exposes :import, "Imports images from a directory path (recursively) to your Photostat repository"

    def import
      opts = Trollop::options do
        opt :path, "Local path to import", :required => true, :type => :string, :short => "-p"
      end

      Trollop::die :path, "must be a valid directory" unless File.directory? opts[:path]
      source = File.expand_path opts[:path]
      puts source
    end

    def activate!
      require "active_record"
      @config = YAML::load File.read(File.expand_path "~/.photostat")
      @repo = Pathname.new @config[:repository_path]

      unless File.directory? @repo.join('system').to_s
        Dir.mkdir @repo.join('system').to_s
        Dir.mkdir @repo.join('system', 'logs').to_s
      end

      @db_config = YAML::load File.read(Photostat.root.join('db', 'config.yml').to_s)
      @db_config[:database] = @repo.join('system', 'photostat.db').to_s

      # creating database, establishing connection
      ActiveRecord::Base.logger = Logger.new(@repo.join('system', 'logs', 'db.log').to_s)
      ActiveRecord::Base.establish_connection(@db_config)

      # doing migrations
      migrations_path = Photostat.root.join('db').to_s
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migrator.migrate(migrations_path)      
    end

    def config
      puts
      config_file = File.expand_path "~/.photostat"

      config = {}
      config = YAML::load(File.read config_file) if File.exists? config_file

      config[:repository_path] ||= "~/Photos"
      config[:repository_path] = input("Wanted location for your Photostat repository", 
                              :dir? => true, :default => config[:repository_path])
      config[:repository_path] = File.expand_path(config[:repository_path])

      puts
      unless File.directory? config[:repository_path]
        Dir.mkdir config[:repository_path]
        puts " >>>> repository #{config[:repository_path]} created"
      end

      File.open(config_file, 'w') do |fh|
        fh.write(YAML::dump(config))
        puts " >>>> generated ~/.photostat config"
      end  

      db_exists = File.exists? File.join(config[:repository_path], 'system', 'photostat.db')
      activate!
      puts " >>>> database created" unless db_exists

      puts
    end
  end

end
