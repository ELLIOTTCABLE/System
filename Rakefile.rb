require 'fileutils'

# Thanks, StackOverflow
# <https://stackoverflow.com/a/171011/31897>
module OS
   def OS.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
   end

   def OS.mac?
      (/darwin/ =~ RUBY_PLATFORM) != nil
   end

   def OS.unix?
      !OS.windows?
   end

   def OS.linux?
      OS.unix? and not OS.mac?
   end
end

task :default => :setup

desc '(DEFAULT) Set up a new machine'
task :setup => [:hooks, :submodules, :dotfiles]

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
   FileUtils.mkdir_p(Dir.pwd+'/Dotfiles/ssh/identities')
end

desc 'Installs dotfiles from this distribution for the first time'
task :dotfiles => :symlink do
   system "chmod -R u=rwX,go= " + Dir.pwd+'/Dotfiles/ssh'
   system "chmod u=rwX,go= " + Dir.pwd+'/Dotfiles/gnupg'
end

desc 'Symlink dotfiles/dotdirs into home directory'
task :symlink do
  root = File.dirname(File.expand_path(__FILE__))
  files = Dir['Dotfiles/*'] # Get all the files
  files = files.map { |file| File.join( root, file ) } # Create an absolute path from our working directory

  special_links = {}
  user_launch_agents_dir = File.join(root, 'launchd', 'User LaunchAgents')
  if File.directory?(user_launch_agents_dir)
    home_launch_agents = File.expand_path('~/Library/LaunchAgents')
    File.delete(home_launch_agents) if File.symlink?(home_launch_agents)
    Dir.mkdir(home_launch_agents) unless Dir.exist?(home_launch_agents)
    Dir.glob(File.join(user_launch_agents_dir, '**', '*.plist')).each do |plist|
      target = File.join(home_launch_agents, File.basename(plist))
      File.delete(target) if File.symlink?(target) || File.exist?(target)
      FileUtils.ln_s(plist, target)
    end
  end

  puts "Linking in $HOME/"
  files.each do |from|
    next unless (File.file?(from) || File.directory?(from))

    home = File.expand_path('~/')
    to = if from.include?('/Dotfiles/')
      File.join(home, '.' + File.basename(from))
    else
      File.join(home, File.basename(from))
    end

    if File.exist?(to)
      print "   ! #{to} exists... "
      if File.symlink? to
        FileUtils.rm to
        puts "as a symlink, removed"
      else
        print "as a normal file/directory, moving to #{File.basename(to)}~ ..."
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

  # Avoid recreating symlink for LaunchAgents directory; handled above.
  next if from == user_launch_agents_dir
  FileUtils.symlink(from, to)
  end
end
