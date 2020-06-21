require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "shipment-tracking@amazon.com",
        "order-update@amazon.com"
    ],
    header :comparator "i;unicode-casemap" :contains "Subject" "Your Amazon.com order",
    header :comparator "i;unicode-casemap" :matches "Subject" ["* has shipped", "Delivered: *"]
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";
} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "auto-confirm@amazon.com",
        "digital-no-reply@amazon.com",
        "donotreply@audible.com"
    ],
    header :comparator "i;unicode-casemap" :contains "Subject" ["Your Amazon.com order", "Amazon.com order of", "Thank you for shopping on Amazon"]
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
