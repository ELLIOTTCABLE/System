require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" "help@dixiemech.com",
   address :all :comparator "i;unicode-casemap" :is "To" "dixiemech.store-promos@from.ec"
) {
   fileinto "Auto";
   fileinto "Auto\\/Promo";
}
