require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}


if address :all :comparator "i;unicode-casemap" :is "From" [
   "meundies@mail.meundies.com",
   "meundies@email.meundies.com"
] {
   fileinto "Auto";
   fileinto "Auto\\/Promo";


} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "support@info.meundies.com",
      "meundies@support.meundies.com"
   ],
   header :comparator "i;unicode-casemap" :contains "Subject" [
      "Your Order Is About to Ship 👀",
      "Your Order Has Shipped 📪",
      "Your Order is About to Ship"

   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";


} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "support@info.meundies.com",
      "meundies@support.meundies.com"
   ],
   header :comparator "i;unicode-casemap" :contains "Subject" [
      "Order Received (Thanks!)",
      "Thanks for Your Order"
   ]
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}

