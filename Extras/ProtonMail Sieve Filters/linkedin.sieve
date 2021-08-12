require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

if allof (
    address :all :comparator "i;unicode-casemap" :is "From" [
        "jobalerts-noreply@linkedin.com",
        "updates-noreply@linkedin.com"
    ],
    header :comparator "i;unicode-casemap" :matches "Subject" [
        "1 new job for '*'",
        "* new jobs for '*'"
    ]
) {
    fileinto "Auto";
    fileinto "Auto\\/Notif";

} elsif address :all :comparator "i;unicode-casemap" :is "From" "inmail-hit-reply@linkedin.com"
{
    fileinto "Convo";
    fileinto "Convo\\/Opportunity";
}

