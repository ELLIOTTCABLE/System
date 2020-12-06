require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" ["capitalone@notification.capitalone.com"],
   header :comparator "i;unicode-casemap" :is "Subject" [
      "Your AutoPay payment is scheduled for *",
      "Your card statement is ready",
      "Your credit card payment is due",
      "Your payment has posted"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";
}
