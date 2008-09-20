require 'fileutils'

task :default => :setup

desc 'Installs dotfiles from this distribution for the first time'
task :setup do
  
  def sudo &block
    raise "Please re-run as root!" unless %x[whoami] == 'root'
    yield
  end
  
  # Map special locations
  locations = {
    :home   => File.expand_path('~'),
    :etc    => '/etc',
    :bin    => File.join(File.expand_path('~'), 'bin')
  }
  
  Dir['*'].each do |location|
    next unless File.directory? location
    next if ENV['DIR'] && ENV['DIR'] != location
    next unless locations.include? location.to_sym
    
    sudo { FileUtils.mkdir_p(locations[location.to_sym]) }
    
    # Damn the ghey Dir['*']'s ignoring of dotfiles!
    files = Dir.new(location).entries # Get all the files
    files = files.reject { |file| file =~ /\.\.?$/ } # Remove superfluous '.' and '..' entries
    files = files.map { |file| File.join(location, file) } # Finally, create an absolute path from our working directory
    
    puts "Linking in #{location}:"
    files.each do |from|
      next unless (File.file?(from) || File.directory?(from))
      
      parent = File.dirname(from).split('/').first
      to = File.join(locations[parent.to_sym], File.basename(from))
      
      from = File.join(FileUtils.pwd, from)
      
      puts " - " + [from, to].join(' -> ')
      if File.exists?(to)
        print "   ! Target exists... "
        if File.symlink? to
          FileUtils.rm to
          puts "as a symlink, removed"
        else
          print "as a normal file/directory, moving to #{File.basename(to)}~... "
          toto = to + '~'
        
          if File.exist? toto
            print "already exists! r)emove, or s)kip? "
            order = STDIN.gets.chomp
          
            case order
            when 'r'
              print '   ! Removing... '
              sudo { FileUtils.rm toto }
            when 's'
              puts '   ! Okay, skipped '
              next
            else
              puts "   ! Invalid entry, so skipping"
              next
            end
          end
        
          sudo { FileUtils.mv to, toto }
          puts "Done!"
        end
      end
      
      sudo { FileUtils.symlink(from, to) }
    end
  end
end