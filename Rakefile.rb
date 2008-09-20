require 'fileutils'

task :default => :setup

desc 'Installs dotfiles from this distribution for the first time'
task :setup do
    
  files = Dir['*'] # Get all the files
  files = files.reject {|f| f =~ /^(Rakefile|README)/i}
  files = files.map { |file| File.join( File.dirname(File.expand_path(__FILE__)), file ) } # Finally, create an absolute path from our working directory
  
  puts "Linking in $HOME/"
  files.each do |from|
    next unless (File.file?(from) || File.directory?(from))
    
    to = File.join(File.expand_path('~/'), '.' + File.basename(from))
    
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
            FileUtils.rm toto
          when 's'
            puts '   ! Okay, skipped '
            next
          else
            puts "   ! Invalid entry, so skipping"
            next
          end
        end
      
        FileUtils.mv to, toto
        puts "Done!"
      end
    end
    
    FileUtils.symlink(from, to)
  end
end
