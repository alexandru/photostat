module Photostat
  module OSUtils
    def input(msg, options=nil)
      options ||= {}
      default = options[:default]
      is_dir  = options[:dir?]

      if default and !default.empty?        
        msg = msg + " (#{default}): "
      else
        msg = msg + ": "
      end

      print msg
      resp = nil

      while not resp
        resp = STDIN.readline.strip
        resp = default if !resp or resp.empty?
        resp = File.expand_path resp if is_dir and resp and !resp.empty?

        error_msg = "Invalid response"

        is_not_dir = false
        if resp and !resp.empty? and !File.directory? resp
          is_not_dir = true if File.exists? resp
          is_not_dir = true unless File.directory? File.dirname(resp)
          error_msg = "Invalid directory path"
        end

        if !resp or resp.empty? or is_not_dir
          puts "ERROR: #{error_msg}!"
          print "\nTry again, #{msg}"
          resp = nil
        end
      end

      return resp
    end

    def exec(*params)
      cmd = Escape.shell_command(params)
      out = `#{cmd} 2>&1`
      unless $?.exitstatus == 0
        raise "Command exit with error!\nCommand: #{cmd}\nOut: #{out}"
      end
      return out
    end    
  end
end
