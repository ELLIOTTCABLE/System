require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" "notify@simple.com",
   header :comparator "i;unicode-casemap" :is "Subject" [
      "We sent you a verification code via text message.",
      "Your interest rate is changing",
      "New message from Simple"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";
}
