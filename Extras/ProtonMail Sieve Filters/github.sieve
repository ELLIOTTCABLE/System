require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["noreply@github.com"],
    header :comparator "i;unicode-casemap" :is "Subject" [
        "[GitHub] A third-party OAuth application has been added to your account",
        "[GitHub] A personal access token has been added to your account"
    ]
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif allof (
    address :all :comparator "i;unicode-casemap" :is "From" ["noreply@github.com"],
    header :comparator "i;unicode-casemap" :matches "Subject" "[GitHub] Payment Receipt for *"
) {
    fileinto "!!";
    fileinto "!!\\/Receipt";
}
