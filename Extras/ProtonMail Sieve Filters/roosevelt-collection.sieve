require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}


if allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "loftsroosevelt@bozzuto.com",
      "contactus@comvibe.com"
   ],
   header :comparator "i;unicode-casemap" :is "Subject" [
      "You have a delivery",
      "You have deliveries",
      "Your delivery has been picked up",
      "Your deliveries have been picked up",
      "We got the message.",
      "Consider it done."
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";


} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "noreply@risebuildings.com"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "* is here!"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";


} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "noreply@bozzuto.com",
      "noreply@gozego.com",
      "ebill@ebill.conservicemail.com"
   ],
   header :comparator "i;unicode-casemap" :is "Subject" [
      "Payment Receipt",
      "Billing Statement",
      "Monthly Conservice Statement for Roosevelt Collection Lofts"
   ]
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}
