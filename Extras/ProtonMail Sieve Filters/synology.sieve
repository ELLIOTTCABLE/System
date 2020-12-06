require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest", "envelope"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
   return;
}

if allof (
   envelope :comparator "i;unicode-casemap" :is "From" ["me@ell.io"],
   address :localpart :comparator "i;unicode-casemap" :is "To" ["ds.ell.io"],
   header :comparator "i;unicode-casemap" :matches "Subject" [
      "[ds.ell.io] Updates are available for packages on Redshirt",
      "[ds.ell.io] Packages on Redshirt are out-of-date",
      "[ds.ell.io] Issues occurred to drive *",
      "[ds.ell.io] Drive * in DS1815+ is failing",
      "[ds.ell.io] IP address [*] has been blocked by Redshirt via SSH"
   ]
) {
   fileinto "Auto";
   fileinto "Auto\\/Notif";
}
