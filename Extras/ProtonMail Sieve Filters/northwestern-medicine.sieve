require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["NO-REPLY@NM.ORG"],
    header :comparator "i;unicode-casemap" :is "Subject" [
        "New Message Available",
        "Upcoming appointment with Northwestern Medicine",
        "New result(s) or new comments to a prior result available",
        "New App Linked to your MyChart Account",
        "New Device Linked to your MyChart Account"
    ]
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["NO-REPLY@NM.ORG"],
    header :comparator "i;unicode-casemap" :matches "Subject" [
        "New Billing Statement Available",
        "Thank you for your payment!"
    ]
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
