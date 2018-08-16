#!/bin/bash
# refreshes gpg keys one by one with a random time interval
# from: <https://riseup.net/en/security/message-security/openpgp/best-practices>
while true
do
  for fingerprint in $(gpg --list-keys --with-colons --with-fingerprint | grep --after-context "1" "^pub" | grep "^fpr" | cut -d ":" -f "10" | sort --random-sort)
  do
    sleep $(( (RANDOM % 1000) + 300))
    gpg --batch --no-tty --no-auto-check-trustdb --refresh-keys "$fingerprint" 2> /dev/null
  done
done
