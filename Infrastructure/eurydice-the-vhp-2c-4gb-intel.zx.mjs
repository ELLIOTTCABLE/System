#!/usr/bin/env zx
import "zx/globals"
import JSON5 from "json5"

let reserved_ips = await $`curl "https://api.vultr.com/v2/reserved-ips" \\
   -K <(cat <<<"oauth2-bearer = \\"$(op read 'op://Shared with Work Computer/Vultr/API/API key')\\"") \\
   -X GET`

console.log("\n")
let ips = JSON.parse(reserved_ips.stdout).reserved_ips.filter(
   (ip) => ip.region === "ord" && ip.ip_type === "v4",
)

ips.forEach((ip) => {
   console.log(`For ${ip.subnet}, use "${ip.id}"`)
})

let ip_id = ips.length >= 0 ? await question("Paste an IP ID: ") : undefined
if (ip_id.trim() === "") ip_id = undefined

if (ip_id) console.log(`Using IP ID: ${ip_id}`)

// ```sh
// json5 eurydice-the-vhp-2c-4gb-intel.jsonc |
//    jq ".user_data = \"$(base64 -i user-data.yaml)\"" |
//    curl "https://api.vultr.com/v2/instances" \
//       -K <(cat <<<"oauth2-bearer = \"$(op read 'op://Shared with Work Computer/Vultr/API/API key')\"") \
//       -X POST \
//       -H "Content-Type: application/json" \
//       --data '@-'
// ```

let json = JSON5.parse(await $`cat eurydice-the-vhp-2c-4gb-intel.jsonc`)

if (ip_id) json.reserved_ipv4 = ip_id

let user_data = await $`base64 -i user-data.yaml`
json.user_data = user_data.toString().trim()

let result = await $`curl "https://api.vultr.com/v2/instances" \\
   -K <(cat <<<"oauth2-bearer = \\"$(op read 'op://Shared with Work Computer/Vultr/API/API key')\\"") \\
   -X POST \\
   -H "Content-Type: application/json" \\
   --data ${JSON.stringify(json)}`

if (result.exitCode === 0) {
   let output = JSON.parse(result.stdout)
   console.log(JSON.stringify(output, null, 3))

   console.log(`View boot console: https://my.vultr.com/subs/vps/novnc/?id=${output.id}`)
}
