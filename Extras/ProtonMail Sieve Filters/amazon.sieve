require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}


if allof (
   address :all :comparator "i;unicode-casemap" :is "From" "store-news@amazon.com",
   header :comparator "i;unicode-casemap" :matches "Subject" "elliott cable: New from *"
) {
   fileinto "Auto";
   fileinto "Auto\\/Promo";


# Generic format for a bunch of delivery notifications
} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "shipment-tracking@amazon.com",
      "order-update@amazon.com"
   ],
   header :comparator "i;unicode-casemap" :contains "Subject" [
      "Your Amazon.com order",
      "Your AmazonSmile order",
      "Your Amazon Fresh order"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "* has shipped",
      "Delivered: *",
      "* has been delivered, now rate your experience"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";


} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "no-reply@amazon.com",
      "do-not-reply@audible.com"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Your Subscribe & Save Subscription at amazon.com",
      "Your new subscription",
      "Delivery delayed",
      "Out of stock item: review your upcoming delivery",
      "Important Note About Your Membership - Credits Expiring Soon!",
      "You’ve got * credits and * credit is expiring soon!",
      "Your Monthly Audible Credit Summary"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";


} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "no-reply@amazon.com",
      "auto-confirm@amazon.com",
      "digital-no-reply@amazon.com",
      "donotreply@audible.com" # yes, it's different, wtf
   ],
   header :comparator "i;unicode-casemap" :contains "Subject" [
      "Review your upcoming delivery",
      "Your Amazon.com order",
      "Amazon.com order of",
      "Your Amazon Fresh order has been received",
      "Thank you for shopping on Amazon",
      "Thanks, your order is complete."
   ]
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}
