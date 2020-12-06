require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" ["do-not-reply@stackoverflow.email"],
   header :comparator "i;unicode-casemap" :is "Subject" [
      "New jobs that match your saved search on Stack Overflow",
      "1 new item in your Stack Exchange inbox",
      "* new items in your Stack Exchange inbox"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";

} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" ["do-not-reply@stackoverflow.email"],
   header :comparator "i;unicode-casemap" :matches "Subject" "The Overflow #*: *"
) {
   fileinto "Auto";
   fileinto "Auto\\/Newsletter";
}
