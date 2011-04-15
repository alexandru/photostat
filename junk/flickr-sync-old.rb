require "optparse"
require 'yaml'
require 'flickraw'
require 'ostruct'
require 'benchmark'


module FlickrCLI

  class Image
    attr_accessor :md5, :local_path, :photoid

    def self.from_path(path)
      img = Image.new
      img.local_path = path
      img.md5 = calculate_md5(path)
      return img
    end

    def self.calculate_md5(file)
      out = `md5sum #{file}`
      out =~ /^(\S+)/
      $1.strip
    end

    def flickr_id!
      if not @photoid and md5
        photos  = flickr.photos.search(:user_id => "me", :tags => "checksum:md5=" + md5)
        @photoid = photos[0].id if photos and photos.size > 0
      end
      @photoid
    end

    def upload(options)
      set_name = options.delete(:set)

      options[:title] ||= File.basename(local_path)
      options[:tags] ||= ''
      options[:tags] += ' sync checksum:md5=' + md5
      options[:safety_level] ||= '1'
      options[:content_type] ||= '1'
      options[:is_family] ||= '0'
      options[:is_friend] ||= '0'
      options[:is_public] ||= '0'
      options[:hidden] ||= '2'

      photoid = flickr.upload_photo(local_path, options)
      raise "Upload failed for #{local_path}" if not photoid

      #if set_name
      #  set = flickr.photosets.getList.find {|set| set.title == set_name}
      #  if not set
      #    set = flickr.photosets.create(:title => set_name, :primary_photo_id => photoid)
      #  else
      #    flickr.photosets.addPhoto(:photoset_id => set.id, :photo_id => photoid)
      #  end
      #end      
    end
  end


  class ImageService
    def initialize
      @cache_file = ENV['HOME'] + "/.flickr-cli/flickr-id-md5-cache"
      @local_images = []

      if File.exists? @cache_file
        @cache = YAML::load_file(@cache_file)
      else
        @cache = {}
      end
    end

    def image_from_path(path)
      img = Image.from_path(path)
      img.photoid = @cache[img.md5]

      if not img.photoid
        photoid = img.flickr_id!
        @cache[img.md5] = photoid
      end

      @local_images << img
      return img
    end

    def save
      File.open(@cache_file, 'w') do |f|
        f.write(@cache.to_yaml)
      end
    end

    def self.open
      fh = ImageService.new      
      yield fh
    ensure
      fh.save if fh
    end

    def self.search_local_dir(directory)
      files = Dir[File.join(directory, "**", "*")].find_all{|path| path =~ /\.(jpe?g|png)$/i }
      total = files.size
      count = 0

      benchmarks = []
      last_avg  = nil

      self.open do |service|
        files.each {|path|

          uploaded = false
          bm = Benchmark.measure do
            count += 1
            img = service.image_from_path(path)

            stats = OpenStruct.new
            stats.count = count
            stats.total = total
            stats.unit_time = last_avg

            est = last_avg ? (total - count) * last_avg : nil
            stats.estimate_time = est

            unless img.photoid
              yield img, stats 
              uploaded = true
            end
          end

          if uploaded
            benchmarks << bm.to_a[-1]
            bp = benchmarks.size >= 10 ? benchmarks[-10,10] : benchmarks
            last_avg = bp.inject{|m,e| m+e} / bp.size 
          end
        }
      end
    end
  end


  class << self

    # Takes a period of time in seconds and returns it in human-readable form (down to minutes)
    def time_period_to_s(time_period)
      begin
        time_period = time_period.to_i
        return nil if time_period == 0
      rescue
        return nil
      end

      interval_array = [ [:weeks, 604800], [:days, 86400], [:hours, 3600], [:mins, 60] ]
      parts = []

      interval_array.each do |sub|
        if time_period>= sub[1] then
          time_val, time_period = time_period.divmod( sub[1] )          
          name = sub[0].to_s

          if time_val > 0
            parts << "#{time_val} #{sub[0]}"
          end
        end
      end
      
      return parts.join(', ')
    end

    def get_config_options
      conf_file = ENV['HOME'] + "/.flickr-cli/config"
      YAML::load_file(conf_file)
    end

    def authenticate(config)
      FlickRaw.api_key = config[:app][:api_key]
      FlickRaw.shared_secret = config[:app][:shared_secret]
      
      flickr.auth.checkToken :auth_token => config[:user][:auth_token]
    end

    def synchronize_directory(directory, options)
      config = get_config_options
      auth = authenticate(config)

      puts "UPLOADING to Flickr ...\n"
      ImageService.search_local_dir(directory) do |img, stats|
        estimate = time_period_to_s(stats.estimate_time)
        $stdout.write "\rProgress: #{stats.count} / #{stats.total}" + (estimate ? " (remaining: #{estimate})" : '')
        img.upload(:tags => "cristian baby sync private", :is_public => '0', :is_friend => "0", :is_family => "1", :safety_level => "1", :hidden => "2")
      end

      puts "\nDONE!\n"
    end

    def run
      options = OpenStruct.new

      command = nil      
      command = ARGV[0] if ARGV.length

      parser = OptionParser.new do |opts|
        opts.program_name = "Flickr Sync"
        opts.banner = "\nUsage: #$0 <directory> [options]\n\n"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          puts
          exit
        end
      end

      begin
        directory = ARGV && ARGV[0]
        if not directory or not File.directory?(directory)
          raise OptionParser::MissingArgument, "<directory>"
        end

        parser.parse!

        conf_file = ENV['HOME'] + "/.flickr-cli/config"
        if not File.exists?(conf_file)
          raise "Configuration file missing, run ./flickr-conf"          
        end

      rescue Exception => e
        unless e.to_s == 'exit'
          puts
          puts "ERROR: #{e}"
          puts
        end
        exit
      end

      synchronize_directory(directory, options)
    end
  end
end


if __FILE__ == $0
  FlickrCLI::run
end
