require 'logger'
require 'ruby-debug'
require 'trollop'

module Photostat
  
  module Plugins
    def self.all_in_order
      unless @plugins_ordered
        @plugins_ordered ||= []
      end
      @plugins_ordered
    end

    def self.all
      unless @plugins
        @plugins ||= {}
      end
      @plugins
    end

    class Base
      def self.help_text(msg=nil)
        @help_text = msg if msg
        @help_text
      end

      def self.exposes_help
        @exposes_help
      end

      def self.exposes(name=nil, help_text=nil)
        @exposes_names ||= []
        @exposes_help ||= {}

        if name
          @exposes_names << name
          @exposes_help[name] = help_text if help_text          
        end
        @exposes_names
      end

      def self.register_plugin(sub)
        sub.name =~ /Photostat[:]{2}(\w+)/
        name = $1

        new_name = ''
        name.each_char do |ch|
          if ch != ch.downcase
            ch = ch.downcase
            ch = "_" + ch if new_name.length > 0
          end
          new_name += ch
        end

        sub.instance_variable_set :@plugin_name, new_name
        ::Photostat::Plugins.all[new_name] = sub
        ::Photostat::Plugins.all_in_order << sub
      end

      def self.inherited(sub)
        register_plugin sub
      end

      def self.included(sub)
        register_plugin sub
      end

      def self.extended(sub)
        register_plugin sub
      end

      def self.plugin_name
        @plugin_name
      end

      def activate!
        # blank
      end

      def help
        puts "Photostat version #{Photostat::VERSION}"
        puts "Plugin: " + self.class.plugin_name.upcase
        puts
        puts "Usage: photostat <command> [options]*"
        puts "For help on each individual command: photostat <command> --help"
        puts
        puts "Where command is one of the following:"
        self.class.exposes.each do |name|
          msg = "  #{self.class.plugin_name}:#{name}"
          if self.class.exposes_help[name]
            msg += "\t- " + self.class.exposes_help[name] 
          end
          puts msg
        end 
        puts
      end

      def config
        # blank
      end
    end
  end

end
