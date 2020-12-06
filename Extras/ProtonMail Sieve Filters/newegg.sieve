require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

/**
 * @type and
 * @comparator is
 */
if allof (address :all :comparator "i;unicode-casemap" :is "From" "Promo@promo.newegg.com") {
   fileinto "Auto";
   fileinto "Auto\\/Promo";
} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" ["info@newegg.com"],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "We've Received Your Newegg Order",
      "Your Payment Has Been Authorized",
      "Here's Your Newegg Invoice",
      "Your Newegg Tracking Number Has Been Created",
      "Your * Has Been Charged",
      "Your Newegg Package Has Been Delivered"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";

} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" ["info@newegg.com"],
   header :comparator "i;unicode-casemap" :matches "Subject" "Here's Your Newegg Invoice"
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}
