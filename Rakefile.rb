require 'fileutils'

task :default => :setup

desc '(DEFAULT) Set up a new machine'
task :setup => [:brew_frontload, :hooks, :submodules, :dotfiles, :brew] do
end

desc 'Install the git hooks'
task :hooks do
   system "./Scripts/install-git-hooks.sh"
end

desc 'Checks out the dotfiles submodules'
task :submodules do
   # What a hack! :D
   system "git submodule update --init --recursive --jobs 4"
   FileUtils.mkdir_p(Dir.pwd+'/Dotfiles/vim/backup')
   FileUtils.mkdir_p(Dir.pwd+'/Dotfiles/vim/undo')
   FileUtils.mkdir_p(Dir.pwd+'/Dotfiles/ssh/sockets')
end

desc 'Installs dotfiles from this distribution for the first time'
task :dotfiles => :symlink do
   system "chmod 700 " + Dir.pwd+'/Dotfiles/ssh'
end

desc 'Symlink dotfiles/dotdirs into home directory'
task :symlink do
  files = Dir['Dotfiles/*'] # Get all the files
  files = files.map { |file| File.join( File.dirname(File.expand_path(__FILE__)), file ) } # Finally, create an absolute path from our working directory

  puts "Linking in $HOME/"
  files.each do |from|
    next unless (File.file?(from) || File.directory?(from))

    to = File.join(File.expand_path('~/'), '.' + File.basename(from))

    if File.exists?(to)
      print "   ! #{to} exists... "
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

desc 'Install the rest of the Homebrew packages and Mac App Store apps'
task :brew_frontload do
   system "brew bundle --file='" + Dir.pwd+'/Bootstrap/Brewfile.frontload' + "'"
   fail "Error: #{$?}" unless $?.success?
end

desc 'Install the rest of the Homebrew packages and Mac App Store apps'
task :brew => :brew_frontload do
   system "brew bundle --file='" + Dir.pwd+'/Bootstrap/Brewfile' + "'"
   fail "Error: #{$?}" unless $?.success?
end
