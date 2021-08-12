require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}


if allof (
   address :all :comparator "i;unicode-casemap" :is "From" "orders@oe.target.com",
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Come and get it! Your order is ready for in-store pickup at *. Order *.",
      "Your order is ready for in-store pickup at *! Order *",
      "🚘 Come and get it! Your Drive Up order is ready at *. Order *.",
      "🚘 Your Drive Up order is ready at *! Order *",
      "We put items from your order ending in * back on the shelf for now.",
      "Beep beep! Your Drive Up order ending in * was picked up.",
      "Hooray! Your order ending in * was picked up.",
      "Heads up! An item from order * has shipped.",
      "Your item has arrived from order *!",
      "Your items have arrived from order *!"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";

} elsif allof (
   address :all :comparator "i;unicode-casemap" :is "From" "orders@oe.target.com",
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "Thanks for shopping with us! Here's your order #: *",
      "All set! Your Same Day Delivery order ending in * is confirmed.",
      "You've successfully canceled items from your order ending in *.",
      "You’re getting a refund for items in your order ending in *."
   ]
) {
   fileinto "!!";
   fileinto "!!\\/Receipt";
}

