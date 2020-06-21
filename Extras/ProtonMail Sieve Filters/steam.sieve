require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["noreply@steampowered.com"],
    anyof (
        header :comparator "i;unicode-casemap" :is "Subject" "An item on your Steam wishlist is on sale!",
        header :comparator "i;unicode-casemap" :matches "Subject" [
            "* items from your Steam wishlist are on sale!",
            "* is now available in Early Access on Steam!",
            "* is now available on Steam!",
            "* Now Available",
            "*, New Update"
        ]
    )
) {
    fileinto "Auto";
    fileinto "Auto\\/Promo";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["noreply@steampowered.com"],
    header :comparator "i;unicode-casemap" :is "Subject" [
        "Thank you for your Steam purchase!",
        "Thank you for activating your product on Steam!"
    ]
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
