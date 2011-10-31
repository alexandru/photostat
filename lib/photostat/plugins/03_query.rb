module Photostat
  class Query < Plugins::Base
    include OSUtils

    help_text "For querying the local repo database"

    exposes :list, "Lists photos corresponding to the filtering criteria"

    def list
      opts = Trollop::options do
        opt :visibility, "Specifies visibility of photos, choices are private, protected and public", :type => :string
        opt :sort, "Specify sort field, one example being 'created_at'", :type => :string
        opt :reverse, "Reverses output list", :type => :boolean
        opt :absolute, "Output absolute path", :type => :boolean
      end

      config = Photostat.config
      db = Photostat::DB.instance

      rs = db[:photos]
      rs = rs.where(:visibility => opts[:visibility]) if opts[:visibility]
      rs = rs.order(opts[:sort].to_sym) if opts[:sort]
      rs = rs.reverse if opts[:reverse]      

      rs.each do |obj|
        path = obj[:local_path]
        path = File.expand_path(File.join(config[:repository_path], path)) if opts[:absolute]
        puts path
      end
    end
  end
end
