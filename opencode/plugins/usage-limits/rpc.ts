import { Rpc } from "@opencode/plugin/rpc"

export interface Window {
  readonly label: string
  /** What the window is limited to, such as a model, when it is not the whole plan. */
  readonly scope?: string
  readonly usedPercent: number
  /** Epoch milliseconds. */
  readonly resetsAt?: number
}

export interface Account {
  readonly id: string
  readonly name: string
  readonly plan?: string
  readonly windows: readonly Window[]
  readonly error?: string
  /** The windows are from fetchedAt because the endpoint is rate limited. */
  readonly rateLimited?: boolean
  readonly fetchedAt: number
}

export interface Snapshot {
  readonly accounts: readonly Account[]
}

export const UsageLimits = Rpc.define({
  id: "usage-limits",
  methods: {
    get: {
      input: { type: "object", additionalProperties: false },
      output: {
        type: "object",
        properties: { accounts: { type: "array" } },
        required: ["accounts"],
      },
    },
  },
  events: {},
})
