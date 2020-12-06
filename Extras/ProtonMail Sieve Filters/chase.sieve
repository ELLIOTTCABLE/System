require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "no.reply.alerts@chase.com",
      "no-reply@alertsp.chase.com"
   ],
   header :comparator "i;unicode-casemap" :is "Subject" [
      "Your Chase Credit Card Payment Has Posted",
      "Thank you for scheduling your credit card payment",
      "Your credit card statement is ready"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";
}
