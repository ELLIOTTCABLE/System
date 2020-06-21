require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["USAA.Customer.Service@mailcenter.usaa.com"],
    anyof (
        header :comparator "i;unicode-casemap" :is "Subject" [
            "You Have a New USAA Document",
            "You Have New USAA Documents",
            "View Your USAA Auto and Property Insurance Bill",
            "USAA Auto and Property Insurance Payment Reminder"
        ]
    )
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";
}
