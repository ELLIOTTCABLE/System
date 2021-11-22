require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "route53-dev-admin@amazon.com"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Automatic renewal of * succeeded",
      "[Domain renewing automatically] Your domain * will be automatically renewed"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";

} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "no-reply-aws@amazon.com",
      "associates@amazon.com"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Amazon Web Services Billing Statement Available",
      "Monthly report for Amazon.com Associate ID *"
   ]
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}
