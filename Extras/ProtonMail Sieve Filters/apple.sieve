require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["no_reply@email.apple.com"],
    anyof (
        header :comparator "i;unicode-casemap" :is "Subject" [
            "Your Subscription is Expiring",
            "Your Subscriptions are Expiring",
        ],
        header :comparator "i;unicode-casemap" :matches "Subject" [
            "A sound was played on *",
            "Your shipment is on its way. Order No. *",
            "We're processing your order *"
        ]
    )
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["no_reply@email.apple.com"],
    header :comparator "i;unicode-casemap" :is "Subject" [
        "Your receipt from Apple.",
        "Your Subscription Confirmation",
        "Your Subscription Renewal"
    ]
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
