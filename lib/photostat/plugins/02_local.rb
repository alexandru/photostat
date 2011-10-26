module Photostat

  class Local < Plugins::Base
    include OSUtils
    include FileUtils

    help_text "Manages your local photos repository"

    exposes :config, "Configures your local database, repository path and Flickr login"
    exposes :import, "Imports images from a directory path (recursively) to your Photostat repository"
    exposes :thumbs, "Generates thumbs (needed by the web interface)"

    def activate!
      require "image_science"
      unless @activated
        @db = Photostat::DB.instance
        Photostat::DB.migrate!
        @activated = true
      end
    end

    def thumbs
      activate!

      opts = Trollop::options do; end
      config = Photostat.config
      repo = Pathname.new config[:repository_path]

      p200 = repo.join('system', 'thumbs', '200')
      mkdir_p p200.to_s

      count = 0
      total = @db[:photos].count
      puts

      @db[:photos].each do |photo|
        count += 1
        STDOUT.write "\r - processed thumbnails for images: #{count} / #{total}"
        STDOUT.flush
        
        t200 = p200.join(photo[:local_path]).to_s
        next if File.exists?(t200)

        abs_path = repo.join(photo[:local_path]).to_s
        ImageScience.with_image(abs_path) do |img|
          mkdir_p File.dirname(t200)
          img.cropped_thumbnail(200) do |thumb|
            thumb.save t200
          end
        end
      end
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
      config[:repository_path] = input(
        "Wanted location for your Photostat repository", 
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
