#!/usr/bin/env bunx zx
// Invoke this script with a directory from `Hosts/`, i.e.:
//
// ```sh
// ./vultr-create-instance.zx.mjs ./Hosts/eurydice-the-vhp-2c-4gb-intel
// ```

import "zx/globals"
import assert from "node:assert/strict"
import JSON5 from "json5"

const op_secret_ref = "op://Elliott - Work-visible/Vultr/API/API key"

async function ask_for_ip_id() {
   const reserved_ips = await $`curl "https://api.vultr.com/v2/reserved-ips" \\
      -K <(cat <<<"oauth2-bearer = \\"$(op read ${op_secret_ref})\\"") \\
      -X GET`

   console.log("\n")
   const ips = JSON.parse(reserved_ips.stdout).reserved_ips.filter(
      (ip) => ip.region === "ord" && ip.ip_type === "v4",
   )

   ips.forEach((ip) => {
      console.log(`For ${chalk.green(ip.subnet)}, use "${chalk.green(ip.id)}"`)
   })

   let ip_id = ips.length >= 0 ? await question("Paste an IP ID: ") : undefined
   if (ip_id.trim() === "") ip_id = undefined

   if (ip_id) console.log(`Using IP ID: ${chalk.green(ip_id)}`)
   return ip_id
}

const host_dir = argv._[0]
assert.ok(host_dir, "Please provide a host directory")

const json = JSON5.parse(await $`cat ${host_dir}/vultr-config.jsonc`)

console.log(`\nCreating instance for "${chalk.green(json.hostname)}":`)

switch (typeof argv["reserved-ipv4"]) {
   case "string":
      json.reserved_ipv4 = argv["reserved-ipv4"]
      break
   case "boolean":
      const ip_id = await ask_for_ip_id()
      if (ip_id) json.reserved_ipv4 = ip_id
      break
}

if (await fs.pathExists(`${host_dir}/user-data.yaml`)) {
   json.user_data = (await $`base64 -i ${host_dir}/user-data.yaml`).stdout.trim()
} else {
   console.log("\n" + chalk.red("Warning:") + " No user data provided")
}

console.log("\nCreating instance with this configuration:")
console.log(JSON.stringify(json, null, 3))

const result = await $`curl "https://api.vultr.com/v2/instances" \\
   -K <(cat <<<"oauth2-bearer = \\"$(op read ${op_secret_ref})\\"") \\
   -X POST \\
   -H "Content-Type: application/json" \\
   --data ${JSON.stringify(json)}`

if (result.exitCode === 0) {
   const output = JSON.parse(result.stdout)
   console.log(JSON.stringify(output.instance, null, 3))

   console.log(
      `View boot console: https://my.vultr.com/subs/vps/novnc/?id=${output.instance.id}`,
   )
}
