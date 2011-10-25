module Photostat

  class Config < Plugins::Base
    help_text "Global configuration utils"
    exposes :all, "Configures everything"
    exposes :test, "Tests if configuration is OK"

    def all
      Photostat::Plugins.all_in_order.each do |plugin|
        plugin.new.config
      end
    end

    def test
      # for --help basically
      Trollop::options do; end

      has_errors = false
      puts

      Photostat::Plugins.all_in_order.each do |plugin|
        begin
          plugin.new.activate!
        rescue
          STDERR.puts "ERROR: `#{plugin.plugin_name} not configured properly"
          has_errors = true
        end
      end
      
      unless has_errors
        puts "Everything is fine!" 
      else
        puts
        puts "Action necessary:"
        puts "    photostat config:all"
      end

      puts
    end
  end
end

    
