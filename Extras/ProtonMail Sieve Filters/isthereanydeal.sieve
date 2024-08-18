require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

/**
 * @type and
 * @comparator is
 * @comparator matches
 */
if allof (address :all :comparator "i;unicode-casemap" :is "From" ["waitlist@isthereanydeal.com", "specials@isthereanydeal.com"], header :comparator "i;unicode-casemap" :matches "Subject" ["Waitlist*: *", "Specials: *"]) {
   fileinto "Auto";
   fileinto "Auto\\/Promo";
}
