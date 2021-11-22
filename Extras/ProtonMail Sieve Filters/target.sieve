require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}


if allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "orders@oe.target.com",
      "noreply@targetgiftcardcenter.com",
      "targetcard.services@myredcard.target.com"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Come and get it! Your order is ready for in-store pickup at *. Order *.",
      "Your order is ready for in-store pickup at *! Order *",
      "🚘 Come and get it! Your Drive Up order is ready at *",
      "🚘 Your Drive Up order is ready at *! Order *",
      "🚘 Today's the last day to grab your order *",
      "We put an item from your order ending in * back on the shelf for now.",
      "We put items from your order ending in * back on the shelf for now.",
      "Beep beep! Your Drive Up order ending in * was picked up.",
      "Hooray! Your order ending in * was picked up.",
      "Heads up! An item from order * has shipped.",
      "Your item has arrived from order *!",
      "Your items have arrived from order *!",
      "Good news! A Starbucks® eGift eCard from order * is here.",
      "You’ve been emailed a download link from your order ending in *",
      "Payment Due Reminder",
      "Your statement is available – Reference:*",
      "Your RedCard has been added to a mobile device.",
      "Enter code * in your app Wallet to verify your RedCard.",
      "Requested change(s) have been processed"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";

} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" [
      "orders@oe.target.com",
      "targetcard.services@myredcard.target.com"
   ],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Thanks for shopping with us! Here's your order #: *",
      "All set! Your Same Day Delivery order ending in * is confirmed.",
      "You've successfully canceled items from your order ending in *.",
      "You've successfully canceled an item from your order ending in *.",
      "You’re getting a refund for items in your order ending in *.",
      "A credit posted to your account",
      "Thanks for your payment",
      "Thanks for scheduling your payment"
   ]
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}
