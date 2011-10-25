module Photostat

  class Sample < Plugins::Base
    help_text "Plugin sample"
    exposes :hello,  'Says hello (plugin testing)'

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
