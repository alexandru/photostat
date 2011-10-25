module Photostat

  class Local < Plugins::Base
    include OSUtils
    include FileUtils

    help_text "Manages your local photos repository"

    exposes :config, "Configures your local database, repository path and Flickr login"
    exposes :import, "Imports images from a directory path (recursively) to your Photostat repository"
    exposes :rebuild_db, "In case you deleted your database, this command rebuilds it, populating it with photos from your repository"

    def activate!
      unless @activated
        require "photostat/db/base"
        @db = Photostat::DB.instance
        Photostat::DB.migrate!
        @activated = true
      end
    end

    def rebuild_db
      interrupted = false
      trap("INT") { interrupted = true }

      opts = Trollop::options do
        opt :tags, "List of tags to classify missing pictures", :type => :strings
        opt :visibility, "Choices are 'private', 'protected' and 'public'", :required => true, :type => :string
      end

      Trollop::die :visibility, "is invalid. Choices are: private, protected and public" unless ['private', 'protected', 'public'].member? opts[:visibility]
      opts[:tags] ||= []

      activate!      

      config = Photostat.config
      repo = config [:repository_path]
      puts
      count = 0

      all_files = files_in_dir(repo, :match => /\d{4}\d{2}\d{2}\d{2}\d{2}[-]\w{6}[.](jpe?g|JPE?G)$/, :absolute? => false) do |path|
        break if interrupted
        count += 1
        STDOUT.print "\r - building list of files: #{count}"
        STDOUT.flush
      end

      if interrupted
        puts
        puts " - interrupted by user" 
        puts
        exit 0
      end

      puts
      count, total = 0, all_files.length

      all_files.each do |fpath|
        break if interrupted
        count += 1
        STDOUT.print "\r - processed: #{count} / #{total}"
        STDOUT.flush
        update_photo(repo, fpath, opts)
      end

      if interrupted
        puts
        puts " - interrupted by user" 
        puts
        exit 0
      end

      puts if count
      puts if count
    end

    def import
      opts = Trollop::options do
        opt :path, "Local path to import", :required => true, :type => :string, :short => "-p"
        opt :tags, "List of tags to classify imported pictures", :type => :strings
        opt :visibility, "Choices are 'private', 'protected' and 'public'", :required => true, :type => :string
        opt :move, "Move, instead of copy (better performance, defaults to false, careful)", :type => :boolean
      end

      Trollop::die :path, "must be a valid directory" unless File.directory? opts[:path]
      Trollop::die :visibility, "is invalid. Choices are: private, protected and public" unless ['private', 'protected', 'public'].member? opts[:visibility]
      opts[:tags] ||= []

      activate!

      source = File.expand_path opts[:path] 
      config = Photostat.config

      files = files_in_dir(source, :match => /(.jpe?g|.JPE?G)/, :absolute? => true)
      count, total = 0, files.length
      puts

      interrupted = false
      trap("INT") { interrupted = true }

      files.each do |fpath|        
        break if interrupted
        count += 1

        STDOUT.print "\r - processed: #{count} / #{total}"
        STDOUT.flush

        md5 = file_md5 fpath
        exif = EXIFR::JPEG.new fpath
        dt = exif.date_time

        local_dir  = dt.strftime("%Y-%m")
        local_path = File.join(local_dir, dt.strftime("%Y%m%d%H%M") + "-" + md5[0,6] + ".jpg")
        dest_dir   = File.join(config[:repository_path], local_dir)
        dest_path  = File.join(config[:repository_path], local_path)

        mkdir_p dest_dir
        cp fpath, dest_path unless opts[:move]
        mv fpath, dest_path if opts[:move]
        
        update_photo(config[:repository_path], local_path, opts, md5, exif)
      end

      if !files or files.length == 0
        puts " - nothing to do"
      end
      
      if interrupted
        puts
        puts " - interrupted by user" 
        puts
        exit 0
      end

      puts
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

      puts
    end

  private

    def update_photo(repo, fpath, opts=nil, md5=nil, exif=nil)
      opts ||= {}
      md5 = nil

      photo = @db[:photos].where(:local_path => fpath).first
      photo_id = photo ? photo[:id] : nil

      raise "do not use absolute paths in the database" if fpath =~ /^\//

      unless photo
        abs_fpath = File.join(repo, fpath)
        md5 = file_md5 abs_fpath unless md5

        exif = EXIFR::JPEG.new abs_fpath unless exif
        return unless exif.date_time

        photo_id = @db[:photos].insert(
          :local_path => fpath,
          :md5 => md5,
          :visibility => opts[:visibility],
          :created_at => exif.date_time
        )
      end        

      opts[:tags].each do |name|         
        next unless @db[:tags].where(:name => name, :photo_id => photo_id).empty?
        @db[:tags].insert(:name => name, :photo_id => photo_id)
      end
    end      

  end

end
