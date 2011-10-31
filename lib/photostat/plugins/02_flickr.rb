module Photostat
  class Flickr < Plugins::Base
    include OSUtils
    include FileUtils

    help_text "Manages your Flickr account"

    exposes :config, "Configures Flickr login"
    exposes :sync, "Uploads local photos to Flickr, downloads Flickr tags / visibility info"
    exposes :export, "Exports web page with thumbnails/links of your public Flickr photos"

    def activate!
      return if @activated
      @activated = 1

      # authenticating to Flickr
      require 'flickraw'

      @config = Photostat.config
      config unless @config[:flickr]

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

      Photostat::DB.migrate!
      @db = Photostat::DB.instance
    end

    def update_md5_info_on_files!
      activate!

      rs = @db[:photos].where(:type => "jpg", :md5 => nil)
      
      count = 0
      total = rs.count
      puts if total > 0

      @db[:photos].where(:type => "jpg", :md5 => nil).all do |obj|        
        md5 = file_md5 File.join(@config[:repository_path], obj[:local_path])
        @db[:photos].where(:uid => obj[:uid]).update(:md5 => md5)

        count += 1
        STDOUT.write("\r - processed md5 hash for local files: #{count} / #{total}")
        STDOUT.flush
      end

      puts if total > 0
    end

    def update_flickr_info!
      activate!
      update_md5_info_on_files!

      db = Photostat::DB.instance
           
      rs = flickr.photos.search(:user_id => "me", :extras => 'machine_tags, tags, date_taken, date_upload', :per_page => 500)
      pages_nr = rs.pages
      page_idx = 1

      count = 0
      not_local = 0
      not_tagged = 0
      are_valid = 0
      total = rs.total.to_i

      valid_ids = []

      puts if total > 0
      while rs.length > 0

        rs.each do |fphoto|
          count += 1

          unless fphoto.machine_tags =~ /checksum:md5=(\w+)/
            not_tagged += 1
            next
          end

          md5 = $1
          obj = db[:photos].where(:md5 => md5).first

          if not obj
            not_local += 1
            next
          end

          db[:tags].where(:photo_id => obj[:id]).delete          
          if fphoto[:tags] and !fphoto.tags.empty?
            tags = fphoto.tags.split.select{|x| ! ['private', 'sync'].member?(x) && x !~ /checksum:/}
            tags.each do |tag_name|
              db[:tags].insert(:name => tag_name, :photo_id => obj[:id])
            end
          end

          if fphoto.ispublic == 1
            visibility = 'public'
          elsif fphoto.isfamily == 1
            visibility = 'protected'
          else
            visibility = 'private'
          end

          db[:photos].where(:md5 => md5).update(:has_flickr_upload => true, :visibility => visibility)
          
          STDOUT.write("\r - reading flickr meta: #{count} of #{total}, with #{not_tagged} not tagged on flickr, #{not_local} not local")
          STDOUT.flush
        end  
        
        page_idx += 1
        break if page_idx > pages_nr
        rs = flickr.photos.search(:user_id => "me", :extras => 'machine_tags', :per_page => 500, :page => page_idx)
      end      

      puts("\r - reading flickr meta: #{count} of #{total}, with #{not_tagged} not tagged on flickr, #{not_local} not local")
    end

    def export
      opts = Trollop::options do
        opt :path, "Local path to export web page to", :required => true, :type => :string, :short => "-p"
      end

      Trollop::die :path, "must have valid base directory" unless File.directory? File.dirname(opts[:path])
      Trollop::die :path, "directory already exists" if File.directory? opts[:path]

      activate!
      update_md5_info_on_files!      

      cfg = Photostat.config
      db = Photostat::DB.instance
      Dir.mkdir opts[:path]

      fh = File.open(File.join(opts[:path], 'index.html'), 'w')
                 
      rs = flickr.photos.search(:user_id => "me", :extras => 'machine_tags, tags, date_taken, date_upload', :per_page => 500, :privacy_filter => 1)
      rs.each do |fphoto|
        next unless fphoto.machine_tags =~ /checksum:md5=(\w+)/

        md5 = $1
        obj = db[:photos].where(:md5 => md5).first

        fname = File.basename obj[:local_path]
        src_path = File.join(cfg[:repository_path], obj[:local_path])
        dst_path = File.join(opts[:path], fname)

        cp src_path, dst_path
        fh.write "<a href='http://www.flickr.com/photos/alex_ndc/#{fphoto.id}/in/photostream' target='_blank'>\n"
        fh.write "    <img src='#{fname}' />\n"
        fh.write "</a>\n"
      end      

      fh.close
    end

    def sync
      activate!

      update_md5_info_on_files!
      update_flickr_info!

      db = Photostat::DB.instance
      config = Photostat.config
           
      rs = db[:photos].where(:type => 'jpg', :has_flickr_upload => false)
      total = rs.count
      count = 0

      rs.order('created_at').all do |obj|
        count += 1
        STDOUT.write("\r - uploading file: #{count} / #{total}")
        STDOUT.flush

        src_path = File.join(config[:repository_path], obj[:local_path])

        options = {}
        options[:title] = obj[:uid]
        options[:tags]  = 'sync checksum:md5=' + obj[:md5]
        options[:safety_level] = '1'
        options[:content_type] = '1'
        options[:is_family] = '0'
        options[:is_friend] = '0'
        options[:is_public] = '0'
        options[:hidden] = '2'

        begin
          photoid = flickr.upload_photo(src_path, options)
        rescue
          sleep 5
          # retrying again
          photoid = flickr.upload_photo(src_path, options)
        end
      end

      puts "\n"
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
