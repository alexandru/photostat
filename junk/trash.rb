      puts "Fetching photos in set ..."

      set = flickr.photosets.getList.find {|set| set.title == options.set_name}
      has_set = (set ? true : false)

      debugger

      if has_set
        resp = flickr.photosets.getPhotos(:photoset_id => set.id)
        
        puts resp.to_yaml
        resp.each do |photo|
          puts photo.to_yaml
        end
        exit
      end

      exit
      puts "Indexing local files ..."

      available_files = {}
      photos_list(directory) do |fpath, md5|
        puts "#{md5} #{fpath}"
        raise Exception, "File conflict: #{fpath} #{available_files[md5]}" if available_files[md5]
        available_files[md5] = fpath
      end

      puts "Uploading ..."

      # uploading photos !!!
      available_files.each do |md5, path|
        puts path
        photoid = flickr.upload_photo(path, :title => md5, :tags => "private", :is_public => '0', :is_friend => "0", :is_family => "0", :safety_level => "1", :hidden => "2")
        if not has_set
          set = flickr.photosets.create(:title => "Private", :primary_photo_id => photoid)
          has_set = true
        else
          flickr.photosets.addPhoto(:photoset_id => set.id, :photo_id => photoid)
        end
        puts "... done!"
      end
