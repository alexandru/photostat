require 'digest/md5'

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

    def files_in_dir(dir, options=nil)
      files = []
      dirs  = []
      dir = File.expand_path dir
      current = dir

      return [] unless File.directory? current

      match = options[:match] if options
      not_match = options[:not_match] if options
      non_recursive = options[:non_recursive]
      is_abs = options[:absolute?] or false

      while current        
        Dir.entries(current).each do |name|
          next unless name != '.' and name != '..'
          path = File.join(current, name)

          valid = true
          valid = path =~ match if match and valid
          valid = path !~ not_match if not_match and valid

          if valid
            rpath = path[dir.length+1,path.length]
            yielded = is_abs ? File.join(dir, rpath) : rpath
            files.push yielded
            yield yielded if block_given?
          end

          dirs.push path if !non_recursive and File.directory? path 
        end

        current = dirs.pop
      end

      files
    end

    def file_md5(file)
      Digest::MD5.file(file).hexdigest
    end
  end
end
