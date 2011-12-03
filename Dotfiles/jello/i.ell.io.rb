require 'uri'

Jello::Mould.new do |paste|
  if paste =~ %r{^http://.*}
    uri = URI.parse paste
    p uri
    
    if uri.host == 'i.ell.io'
      uri.host = 'ell.io'
      uri.path.insert 1, 'i'
      `afplay /System/Library/Sounds/Pop.aiff` # Should really add this functionality to Jello.
      uri.to_s
    else; nil; end
  end
end

