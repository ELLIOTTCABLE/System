require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" "no-reply@mail.goodreads.com",
   header :comparator "i;unicode-casemap" :is "Subject" "Comment from *"
) {
   fileinto "Convo";
   fileinto "Convo\\/Notif";

} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" "no-reply@mail.goodreads.com",
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "* Reading Challenge Book Recommendations",
      "New * Books by Authors You've Read",
      "Need a Boost? Your * Reading Challenge Progress",
      "*, the author, shared * from “*”",
      "You finished *. What’s next?"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";
}
