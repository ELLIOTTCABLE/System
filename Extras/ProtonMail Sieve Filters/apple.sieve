require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "noreply@email.apple.com",
        "no_reply@email.apple.com",
        "shipping_notification@orders.apple.com",
        "order_change@store.apple.com",
        "developer@email.apple.com",
        "do_not_reply@itunes.com"
    ],
    anyof (
        header :comparator "i;unicode-casemap" :is "Subject" [
            "Your Subscription is Expiring",
            "Your Subscriptions are Expiring",
            "Your recent download with your Apple ID",
            "Your Membership has been Renewed."
        ],
        header :comparator "i;unicode-casemap" :matches "Subject" [
            "A sound was played on *",
            "Find My has been disabled on *",
            "Your shipment is on its way. Order No. *",
            "Order * change confirmation.",
            "Your Apple ID was used to sign in to iCloud on *",
            "Your Season Pass for *",
            "New episode available for download - *"
        ]
    )
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "no_reply@email.apple.com",
        "no_reply@post.applecard.apple"
    ],
    anyof (
        header :comparator "i;unicode-casemap" :is "Subject" [
            "Your receipt from Apple.",
            "Your Subscription Confirmation",
            "Subscription Confirmation",
            "Your Subscription Renewal",
            "Your payment has been received",
            "Your Apple Card statement is ready"
        ],
        header :comparator "i;unicode-casemap" :matches "Subject" [
            "We're processing your order *"
        ]
    )
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
