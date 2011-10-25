require 'sequel'

module Photostat
  module DB
    def self.instance
      unless @DB
        config = Photostat.config
        path = File.join(config[:repository_path], 'system', 'photostat.db')
        @DB = Sequel.sqlite(path)
      end
      return @DB
    end

    def self.migrate!
      db = self.instance
      Sequel.extension :migration
      Sequel::Migrator.apply(db, File.dirname(__FILE__))
    end
  end
end

