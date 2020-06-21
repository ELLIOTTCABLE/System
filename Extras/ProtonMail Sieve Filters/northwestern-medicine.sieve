require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["NO-REPLY@NM.ORG"],
    header :comparator "i;unicode-casemap" :is "Subject" "New Message Available"
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["NO-REPLY@NM.ORG"],
    header :comparator "i;unicode-casemap" :matches "Subject" "New Billing Statement Available"
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
