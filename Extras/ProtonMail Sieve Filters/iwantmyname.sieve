require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}


if allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "help@support.iwantmyname.com",
        "billing@support.iwantmyname.com"
    ],
    header :comparator "i;unicode-casemap" :matches "Subject" [
        "Domain Name Cancellation *",
        "Your iwantmyname service is about to expire",
        "Your iwantmyname service expired",
        "Your iwantmyname domain renewal payment failed"
    ]
) {
    fileinto "!!";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" "help@support.iwantmyname.com",
    header :comparator "i;unicode-casemap" :is "Subject" "Your domain names will be renewed in 7 days"
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" "billing@support.iwantmyname.com",
    header :comparator "i;unicode-casemap" :matches "Subject" "Thank you for renewing your domain names"
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
