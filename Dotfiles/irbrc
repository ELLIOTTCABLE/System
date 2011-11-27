# Load various things...
# * rubygems for some of the following
# * utility_belt (and wirble) for IRB tools
# * ostruct for OpenStruct.new
# * open-uri (because sometimes rfuzz suxx)
# * color (gem, not default library! see http://rubyforge.org/projects/color/)
#     for color numeric manipulation
# * Etc for accessing /etc/* (Etc.getlogin type stuff)
# * Extensions for .define_method (mostly)
# * hpricot for parsing HTML/XML
# * what_methods ("hello".what? == 5 #=> ["length", "size"])
# * stringIO for custom less and more commands
%w{rubygems wirble ostruct open-uri color etc hpricot what_methods stringio map_by_method}.each { |lib| require lib }
if RUBY_VERSION < "1.9"
  %w{utility_belt}.each { |lib| require lib }
end

unless self.class.const_defined? "IRBRC_HAS_LOADED"
  begin # god knows what all...
    
    def mate *args
      flattened_args = args.map {|arg| "\"#{arg.to_s}\""}.join ' '
      `mate #{flattened_args}`
      nil
    end
  end
  
  begin # Wirble (-:
    # start wirble (with color)
    wirble_opts = {
      # skip shortcuts
      # :skip_shortcuts => true,

      # don't set the prompt
      # :skip_prompt    => true,

      # override some of the default colors
      # :colors         => {
      #   :open_hash    => :green.
      #   :close_hash   => :green.
      #   :string       => :blue,
      # },
    }
    
    # initialize wirble with options above
    # Wirble.init(wirble_opts)
    Wirble.init
    Wirble.colorize
  end

  begin # ANSI codes
    ANSI_BLACK    = "\033[0;30m"
    ANSI_GRAY     = "\033[1;30m"
    ANSI_LGRAY    = "\033[0;37m"
    ANSI_WHITE    =  "\033[1;37m"
    ANSI_RED      ="\033[0;31m"
    ANSI_LRED     = "\033[1;31m"
    ANSI_GREEN    = "\033[0;32m"
    ANSI_LGREEN   = "\033[1;32m"
    ANSI_BROWN    = "\033[0;33m"
    ANSI_YELLOW   = "\033[1;33m"
    ANSI_BLUE     = "\033[0;34m"
    ANSI_LBLUE    = "\033[1;34m"
    ANSI_PURPLE   = "\033[0;35m"
    ANSI_LPURPLE  = "\033[1;35m"
    ANSI_CYAN     = "\033[0;36m"
    ANSI_LCYAN    = "\033[1;36m"

    ANSI_BACKBLACK  = "\033[40m"
    ANSI_BACKRED    = "\033[41m"
    ANSI_BACKGREEN  = "\033[42m"
    ANSI_BACKYELLOW = "\033[43m"
    ANSI_BACKBLUE   = "\033[44m"
    ANSI_BACKPURPLE = "\033[45m"
    ANSI_BACKCYAN   = "\033[46m"
    ANSI_BACKGRAY   = "\033[47m"

    ANSI_RESET      = "\033[0m"
    ANSI_BOLD       = "\033[1m"
    ANSI_UNDERSCORE = "\033[4m"
    ANSI_BLINK      = "\033[5m"
    ANSI_REVERSE    = "\033[7m"
    ANSI_CONCEALED  = "\033[8m"

    XTERM_SET_TITLE   = "\033]2;"
    XTERM_END         = "\007"
    ITERM_SET_TAB     = "\033]1;"
    ITERM_END         = "\007"
    SCREEN_SET_STATUS = "\033]0;"
    SCREEN_END        = "\007"
  end

  begin # Custom Prompt
    if ENV['RAILS_ENV']
      name = "rails #{ENV['RAILS_ENV']}"
      colors = ANSI_BACKBLUE + ANSI_YELLOW
    else
      name = "ruby"
      colors = ANSI_BACKPURPLE + ANSI_YELLOW
    end

    if IRB and IRB.conf[:PROMPT]
      # :XMP
      IRB.conf[:PROMPT][:XMP][:RETURN] = "\010\# => %s\n"
      IRB.conf[:PROMPT][:XMP][:PROMPT_I] = ""
      IRB.conf[:PROMPT][:XMP][:AUTO_INDENT] = true
      
      # :SD
      IRB.conf[:PROMPT][:SD] = {
        :PROMPT_I => "#{colors}#{name}: %m #{ANSI_RESET}\n" \
        + ">> ", # normal prompt
        :PROMPT_S => "%l> ",  # string continuation
        :PROMPT_C => " > ",   # code continuation
        :PROMPT_N => " > ",   # code continuation too?
        :RETURN   => "#{ANSI_BOLD}# => %s  #{ANSI_RESET}\n\n",  # return value
        :AUTO_INDENT => true
      }
      
      # :SIMPLE, :DEFAULT, :XMP. :SD
      IRB.conf[:PROMPT_MODE] = :XMP
    end
  end

  begin # Utility methods
    def pm(obj, *options) # Print methods
      methods = obj.methods
      methods -= Object.methods unless options.include? :more
      filter = options.select {|opt| opt.kind_of? Regexp}.first
      methods = methods.select {|name| name =~ filter} if filter

      data = methods.sort.collect do |name|
        method = obj.method(name)
        if method.arity == 0
          args = "()"
        elsif method.arity > 0
          n = method.arity
          args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")})"
        elsif method.arity < 0
          n = -method.arity
          args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")}, ...)"
        end
        klass = $1 if method.inspect =~ /Method: (.*?)#/
        [name, args, klass]
      end
      max_name = data.collect {|item| item[0].size}.max
      max_args = data.collect {|item| item[1].size}.max
      data.each do |item| 
        print " #{ANSI_BOLD}#{item[0].rjust(max_name)}#{ANSI_RESET}"
        print "#{ANSI_GRAY}#{item[1].ljust(max_args)}#{ANSI_RESET}"
        print "   #{ANSI_LGRAY}#{item[2]}#{ANSI_RESET}\n"
      end
      data.size
    end
  end
  
  begin # Mockingbird
    class Object;
      def mock_methods(mock_methods);
        original = self;
        klass = Class.new(self) do; 
          instance_eval do; 
            mock_methods.each do |method, proc|; 
              define_method("mocked_#{method}", &proc);
              alias_method method, "mocked_#{method}";
            end;
          end;
        end;

        begin;
          Object.send(:remove_const, self.name.to_s);
          Object.const_set(self.name.intern, klass);
          yield;
        ensure;
          Object.send(:remove_const, self.name.to_s);
          Object.const_set(self.name.intern, original);
        end;
      end;
    end
  end
  
  begin # Copious output helper (-;
    def less
      spool_output('less')
    end

    def most
      spool_output('most')
    end

    def spool_output(spool_cmd)
      $stdout, sout = StringIO.new, $stdout
      yield
      $stdout, str_io = sout, $stdout
       IO.popen(spool_cmd, 'w') do |f|
         f.write str_io.string
         f.flush
         f.close_write
       end
    end
  end
  
  ARGV.concat [ "--readline", "--prompt-mode", "simple" ]
  IRBRC_HAS_LOADED = true
end

puts '# IRB loaded...' if IRBRC_HAS_LOADED