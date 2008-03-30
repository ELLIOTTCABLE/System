desc 'Installs dotfiles from this distribution for the first time'
task :setup do
  require 'fileutils'
  
  def sudo &block
    raise "error - try running as root" unless yield
  end
  
  # Map special locations
  locations = {
    :home   => File.expand_path('~'),
    :etc    => '/etc'
  }
  
  Dir['*'].each do |location|
    next unless File.directory? location
    
    # Damn the ghey Dir['*']'s ignoring of dotfiles!
    files = Dir.new(location).entries # Get all the files
    files = files.reject { |file| file =~ /\.\.?$/ } # Remove superfluous '.' and '..' entries
    files = files.map { |file| File.join(location, file) } # Finally, create an absolute path from our working directory
    
    puts "Linking:"
    files.each do |file|
      next unless File.file? file
      
      parent = File.dirname(file).split('/').first
      to = File.join(locations[parent.to_sym], File.basename(file))
      
      file = File.join(FileUtils.pwd, file)
      
      puts " - " + [file, to].join(' -> ')
      if File.file?(to) || File.symlink?(to)
        print "   ! Target exists... "
        if File.symlink? to
          print "Target is a symlink, removing... "
          FileUtils.rm to
          puts "Done!"
        elsif File.file? to
          print "Target is a normal file, moving to +~... "
          toto = to + '~'
          
          if File.exist? toto
            print "+~file already exists! r)emove, or s)kip? "
            order = gets.chomp
            
            case order
            when 'r'
              print '   ! Removing... '
              sudo { FileUtils.rm toto }
            when 's'
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
      
      sudo { FileUtils.symlink(file, to) }
    end
  end
end