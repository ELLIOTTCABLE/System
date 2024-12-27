import { Client } from "@notionhq/client@2.2.15"
import { getState, setState } from "windmill-client@1.441.0"

type Notion = {
  token: string
}

export async function main(notion: Notion, database_id: string): Promise<any> {
  const n = new Client({
    auth: notion.token,
  })

  let last_seen = await getState()
  console.log(`Fetching pages edited after ${new Date(last_seen).toUTCString()} ...`)

  let filter =
    typeof last_seen == "undefined"
      ? undefined
      : { timestamp: "last_edited_time", last_edited_time: { after: last_seen } }

  let resp = await n.databases.query({
    database_id,
    filter,
    sorts: [
      {
        timestamp: "last_edited_time",
        direction: "ascending",
      },
    ],
  })

  if (resp.results.length > 0) {
    console.log(`Fetched ${resp.results.length} new records`)
    let last_seen = resp.results.at(-1).last_edited_time
    await setState(last_seen)
  } else {
    console.log("No new records found.")
  }

  return resp.results
}
