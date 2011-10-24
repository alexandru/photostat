module Photostat

  class Test < Plugins::Base
    help_text "Tests the plugins system"
    exposes :config, "Tests if configuration is OK"
    exposes :hello,  'Says hello (plugin testing)'

    def config
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

    def hello
      opts = Trollop::options do
        opt :name, "Your name", :required => true, :type => :string
      end

      puts
      puts "Hello " + (opts[:name] || "Anonymous") + "!"
      puts
    end

  end

end
