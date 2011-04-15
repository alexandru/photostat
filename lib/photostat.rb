require 'ostruct'

module Photostat
  VERSION = '0.1'

  class ArgumentError(Exception); end
  class ArgumentRequiredError(ArgumentError); end
  class ArgumentInvalidError(ArgumentError); end

  #  Describes the interface any Photostat command module must
  #  implement.
  module Command
    #  Stores command line arguments
    attr_accessor :argv

    #  Used as a summary specification of the command, to be displayed
    #  in the main help output
    attr-accessor :help_summary

    #  To be displayed in the help output of this specific command (on
    #  "photostat help <command-name>")
    attr-accessor :help_description

    # 
    #  call-seq:
    #     Command#run(argv_array)
    #
    #  Executes the command, passing command-line arguments as an
    #  array (gotten straight from the command-line, with no parsing
    #  done).
    #
    def run(argv)
      raise NotImplementedError
    end

    #  Describes a positional argument, that's always required.  The
    #  actual position in the command-line arguments is relative to
    #  the current command, and to order in which this method was
    #  called.
    def describe_argument(name, description, &process)
      @arguments_spec = [] unless defined? @arguments_spec

      test = @arguments_spec.find{|a| a.name == name}
      raise Exception, "Param #{name} already defined!" if test

      @arguments_spec << OpenStruct.new({
          :name => name,
          :description => description,
          :process => block_given? ? process : nil,
      })
    end

    #  Describes a command line option.
    #
    #  Arguments
    #
    #  - name: indentifier in the options accessor
    #  - short_version: format, single dash, single char
    #  - long_version: format, double dash, double char
    #  - is_required: either true/false or :required/:optional
    #  - type: either :bool (no parameter), or :value (string parameter following)
    #  - description: for showing up in help screens
    #  - &process(value): a block of code used for post-processing the value
    #
    def describe_option(name, short_version, long_version, is_required, type, description, &process)
      @options_spec = [] unless defined? @options_spec

      test = @options_spec.find do |o| 
        o.name == name or o.short_version == short_version or o.long_version == long_version
      end
      if test
        raise Exception, "Param #{name} already defined, with name #{test.name}, " +
          "passed as #{test.short_version} and #{test.long_version}" 
      end
      
      @options_spec << OpenStruct.new({
          :name => name,
          :short_version => short_version,
          :long_version => long_version,
          :is_required => is_required and is_required != :optional,
          :type => [:bool, :value],
          :description => description,
          :process => block_given? ? process : nil,
      })
    end

     
    # Returns parsed command-line options, as an OpenStruct (Hash). 
    # If @parsed_options is not computed, than computes it first.
    def parsed_options
      return @parsed_options if @parsed_options

      @options_spec ||= []
      short_versions = @options_spec.inject({}) {|h,o| h[o.short_version] = h}
      long_versions  = @options_spec.inject({}) {|h,o| h[o.long_version]  = h}

      args_spec = (@arguments_spec || []).clone
      @parsed_options = OpenStruct.new

      expects_value = false
      arg_spec = nil

      argv.each do |arg|
        pos_arg = args_spec.delete_at(0)
        if pos_arg
          @parsed_options[pos_arg.name] = pos_arg.process.call(arg)
        elsif not expects_value
          if arg =~ /^([-]{1,2}[\w-]+)=(.*)$/
            has_val = true
            uid, val = $1, $2
          else
            has_val = false
            uid, val = arg, nil
          end

          arg_spec = @options_spec.find{|o| o.short_version == uid || o.long_version == uid}          
          raise ArgumentInvalidError, "Invalid option - #{arg}" unless arg_spec

          if has_val or arg_spec.type != :bool
            raise ArgumentInvalidError, "Value not provided for #{arg_spec.long_version}" if not val                           
            @parsed_options[arg_spec.name] = arg_spec.process.call(val)
          elsif arg_spec.type != :bool
            expects_value = true
          else # :bool
            @parsed_options[arg_spec.name] = true
          end
        else # expects_value; arg_spec saved from the prev iteration          
          @parsed_options[arg_spec.name] = arg_spec.process.call(arg)
          expects_value = false
        end
      end

      if expects_value
        raise ArgumentInvalidError, "Value not provided for #{arg_spec.long_version}"
      end
    end
  end

  def self.run(argv)
  end
end
