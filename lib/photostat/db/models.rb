module Photostat
  class Photo < ActiveRecord::Base
    set_table_name "photostat_photos"
    validates_uniqueness_of :local_path

    validates_presence_of :md5
    validates_presence_of :visibility
    validates_presence_of :exif_dump

    has_many :tags

    def exif
      YAML.load(self.exif_dump) if self.exif_dump
    end

    def exif=(obj)
      self.exif_dump = YAML.dump(obj)
    end
  end

  class Tag < ActiveRecord::Base
    set_table_name "photostat_tags"
    validates_presence_of :name

    belongs_to :photo
  end
end
