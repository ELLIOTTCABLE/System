require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

# Apple Store order-related *notifications* (not receipts)
if anyof (
    allof (
        address :all :comparator "i;unicode-casemap" :is "From"
            "no_reply@email.apple.com",
        header :comparator "i;unicode-casemap" :is "Subject" [
            "Your Subscription is Expiring",
            "Your Subscriptions are Expiring",
            "Your recent download with your Apple ID",
        ]
    ),
    allof (
        address :all :comparator "i;unicode-casemap" :is "From"
            "do_not_reply@itunes.com",
        anyof (
            header :comparator "i;unicode-casemap" :is "Subject" [
                "A refund request has been received",
                "Decision on refund request",
            ],
            header :comparator "i;unicode-casemap" :matches "Subject" [
                "Your Season Pass for *",
                "New episode available for download - *",
            ]
        )
    ),
    allof (
        address :all :comparator "i;unicode-casemap" :is "From"
            "developer@email.apple.com",
        header :comparator "i;unicode-casemap" :is "Subject"
            "Your Membership has been Renewed."
    ),
    allof (
        address :all :comparator "i;unicode-casemap" :is "From"
            "shipping_notification@orders.apple.com",
        header :comparator "i;unicode-casemap" :matches "Subject"
            "Your shipment is on its way. Order No. *"
    ),
    allof (
        address :all :comparator "i;unicode-casemap" :is "From"
            "order_change@store.apple.com",
        header :comparator "i;unicode-casemap" :matches "Subject"
            "Order * change confirmation."
    ),
    allof (
        address :all :comparator "i;unicode-casemap" :is "From"
            "pickup_notification@orders.apple.com",
        header :comparator "i;unicode-casemap" :matches "Subject"
            "Pickup Information for Order *",
    ),
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";


} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "noreply@email.apple.com",
      # "no_reply@email.apple.com",
      # "shipping_notification@orders.apple.com",
      # "order_change@store.apple.com",
      # "developer@email.apple.com",
      # "do_not_reply@itunes.com"
    ],
    anyof (
        header :comparator "i;unicode-casemap" :is "Subject" [
            "Receipt for your Apple Cash Payment"
        ],
        header :comparator "i;unicode-casemap" :matches "Subject" [
            "A sound was played on *",
            "Find My has been disabled on *",
            "Your Apple ID was used to sign in to iCloud *",
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
