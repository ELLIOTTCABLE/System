def format_glog(f)
   subject = f[1]
   
   # TODO: I need to abstract this into a .gitlabels library.
   if subject and match = subject.match(/^\(([^\)]*)\)\s*/)
      subject.sub! match[0], ''
      tags = match.captures.first.split ' '
      
      minor = !!tags.delete('-')
      subject.prepend "\e[2m" if minor
      
      subject << ' ' << "\e[37;40;4m" << tags.join("\e[24m \e[4m") << "\e[39;49;24m"
   end
   
   subject.sub! /^(\+|!)/, "\e[95m\\1\e[39m" if subject
   
   subject << "\e[22m" if minor
   
   return f
end
