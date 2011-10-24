require "pathname"
require "yaml"
require "logger"
require "escape"
require "exifr"
require 'fileutils'

require "photostat/version"
require "photostat/osutils"
require "photostat/plugins"

module Photostat
  def self.root
    Pathname.new File.join(File.dirname(__FILE__), 'photostat')
  end

  def self.config
    unless @config
      @config = YAML.load(File.read(File.expand_path "~/.photostat"))
    end
    @config
  end

  def self.activate!
    Photostat::Plugins.all_in_order.each do |plugin|      
      plugin.new.activate!
    end
  end

  def self.configure_plugin!(name)
    Photostat::Plugins.all[name.to_s].new.config
  end

  def self.activate_plugin!(name)
    Photostat::Plugin.all[name.to_s].new.activate!
  end

  def self.execute
    cmd, subc = nil, :help
    cmd = ARGV.shift if ARGV and ARGV.length > 0
    if cmd =~ /^(\w+):(\w+)$/
      cmd, subc = $1, $2.to_sym
    end

    all_plugins = Photostat::Plugins.all
    if cmd and all_plugins[cmd]
      all_plugins[cmd].new.send subc
    else
      show_help
    end
  end

  def self.show_help
    puts "Photostat version #{Photostat::VERSION}"
    puts
    puts "Getting help for a particular plugin:   photostat <plugin_name>"
    puts "Getting help for a particular command:: photostat <command> --help"
    puts
    puts "Available plugins:"
    Photostat::Plugins.all.each_key do |cmd_name|      
      cmd_obj = Photostat::Plugins.all[cmd_name]
      help_text = "#{cmd_name}"
      help_text += "\t- #{cmd_obj.help_text}" if cmd_obj.help_text
      puts "  #{help_text}"
    end

    puts
    puts "All available commands:"
    Photostat::Plugins.all.each_key do |cmd_name|
      cmd_obj = Photostat::Plugins.all[cmd_name]
      cmd_obj.exposes.each do |name|
        msg = "  #{cmd_obj.plugin_name}:#{name}"
        if cmd_obj.exposes_help[name]
          msg += "\t- " + cmd_obj.exposes_help[name] 
        end
        puts msg
      end
    end
    puts
  end
end

# including all available plugins
Photostat.root.join('plugins').children.sort.each do |plugin_path|
  next if File.directory? plugin_path
  next unless plugin_path.to_s =~ /.rb$/
  require plugin_path.to_s
end
