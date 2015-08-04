#!/usr/bin/env sh

netrc="${NETRC:-$HOME/.netrc}"
subdomain="${HARVEST_SUBDOMAIN:-elliottcable}"

if [ -f "$netrc" ] && [ ! -d "$netrc" ]; then

   fraction="$(
      curl -s --netrc-file "$netrc"                                        \
         -H 'Content-Type: application/json' -H 'Accept: application/json' \
         "https://${subdomain}.harvestapp.com/daily" |                     \
                                                                           \
      jq --raw-output --exit-status 2>/dev/null                            \
         '.day_entries | reverse | .[0] | .hours'
   )" || exit $?

   seconds="$(echo "(${fraction:-0} * 60 * 60) / 1" | bc)"
   time="$(date -ujr "$seconds" +'%k:%M')"

   printf %s\\n " $time"

else
   exit 255
fi
