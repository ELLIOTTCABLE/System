require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["service@paypal.com"],
    anyof (
        header :comparator "i;unicode-casemap" :matches "Subject" "Receipt for Your Payment*",
        header :comparator "i;unicode-casemap" :matches "Subject" "You sent an automatic payment to*",
        header :comparator "i;unicode-casemap" :is "Subject" "You sent a payment"
    )
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
