require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["orders@eat.grubhub.com"],
    header :comparator "i;unicode-casemap" :matches "Subject" "Your order from * is being prepared"
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";
}

