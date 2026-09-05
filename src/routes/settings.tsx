import { createFileRoute } from "@tanstack/react-router";
import type { ReactNode } from "react";
import { useState } from "react";
import { Check, FolderOpen, Monitor, Moon, Sun } from "lucide-react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import { PrototypeNote, StatusPill } from "@/components/hyperdrop/primitives";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { thisDevice } from "@/lib/hyperdrop";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/settings")({
  head: () => ({
    meta: [
      { title: "Settings — HyperDrop" },
      {
        name: "description",
        content:
          "Device name, discoverability, save location, auto-accept, appearance, local network diagnostics, storage and privacy controls.",
      },
      { property: "og:title", content: "Settings — HyperDrop" },
      {
        property: "og:description",
        content: "Control discoverability, transfer defaults, appearance and privacy.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: SettingsScreen,
});

function SettingsScreen() {
  const [name, setName] = useState(thisDevice.name);
  const [theme, setTheme] = useState<"light" | "dark" | "system">("system");

  return (
    <AppShell>
      <header className="mb-6">
        <h1 className="font-display text-3xl font-semibold">Settings</h1>
        <p className="mt-1.5 text-muted-foreground">
          Everything here is stored on this device. No account, no sync.
        </p>
      </header>

      <div className="grid gap-6 lg:grid-cols-2">
        <Group title="Device">
          <Row label="Device name" hint="What other devices call this device">
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              aria-label="Device name"
              className="h-9 w-44 rounded-lg border border-input bg-surface-raised px-3 text-sm outline-none focus-visible:border-ring"
            />
          </Row>
          <Row label="Device icon" hint="Shown on the other device">
            <Button variant="outline" size="sm">
              Android phone
            </Button>
          </Row>
          <Row label="Connection code" hint="Rotates every 5 minutes">
            <span className="code-digits text-sm font-semibold">482 731</span>
          </Row>
          <Row label="Discoverable" hint="Allow nearby devices to find this one">
            <Switch defaultChecked />
          </Row>
        </Group>

        <Group title="Transfers">
          <Row label="Default save location" hint="C:\Users\Alex\HyperDrop">
            <Button variant="outline" size="sm">
              <FolderOpen className="size-4" /> Change
            </Button>
          </Row>
          <Row label="Auto-accept trusted devices">
            <Switch />
          </Row>
          <Row label="Ask before receiving" hint="Recommended">
            <Switch defaultChecked />
          </Row>
          <Row label="Resume interrupted transfers">
            <Switch defaultChecked />
          </Row>
          <Row label="Maximum concurrent transfers">
            <span className="text-sm font-medium tabular-nums">3</span>
          </Row>
        </Group>

        <Group title="Appearance">
          <Row label="Theme">
            <div className="flex gap-1.5">
              {(
                [
                  ["light", Sun],
                  ["dark", Moon],
                  ["system", Monitor],
                ] as const
              ).map(([key, Icon]) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => setTheme(key)}
                  aria-label={key}
                  className={cn(
                    "flex h-9 items-center gap-1.5 rounded-lg border px-3 text-sm capitalize transition-colors",
                    theme === key
                      ? "border-primary/40 bg-primary/10 text-primary"
                      : "border-border bg-surface-raised text-muted-foreground",
                  )}
                >
                  <Icon className="size-4" aria-hidden /> {key}
                </button>
              ))}
            </div>
          </Row>
          <Row label="Reduce motion" hint="Follows the system setting by default">
            <Switch defaultChecked />
          </Row>
          <Row label="Large text">
            <Switch />
          </Row>
        </Group>

        <Group title="Network">
          <Row label="Local network status">
            <StatusPill tone="success">Connected · Home-5G</StatusPill>
          </Row>
          <Row label="Current connection" hint="Alex's Laptop · Windows">
            <StatusPill tone="primary">Paired</StatusPill>
          </Row>
          <Row label="Transfer protocol status" hint="mDNS advertise + encrypted TCP stream">
            <StatusPill tone="success">Healthy</StatusPill>
          </Row>
          <Row label="Diagnostics">
            <Button variant="outline" size="sm">
              Run check
            </Button>
          </Row>
        </Group>

        <Group title="Storage">
          <Row label="Received files" hint="4.2 GB in HyperDrop folder">
            <Button variant="outline" size="sm">
              Open
            </Button>
          </Row>
          <Row label="Temporary files" hint="311 MB of partial chunks">
            <Button variant="outline" size="sm">
              Clear
            </Button>
          </Row>
        </Group>

        <Group title="Privacy">
          <Row label="Local-only transfer" hint="Files never leave your network">
            <span className="inline-flex items-center gap-1.5 text-sm text-success">
              <Check className="size-4" /> Always on
            </span>
          </Row>
          <Row label="Clear transfer history">
            <Button variant="outline" size="sm">
              Clear
            </Button>
          </Row>
          <Row label="Clear remembered devices">
            <Button variant="outline" size="sm">
              Clear
            </Button>
          </Row>
        </Group>

        <Group title="About">
          <Row label="HyperDrop version" hint="Design reference build">
            <span className="text-sm tabular-nums text-muted-foreground">1.0.0</span>
          </Row>
          <Row label="Open-source licenses">
            <Button variant="ghost" size="sm">
              View
            </Button>
          </Row>
          <Row label="Privacy policy">
            <Button variant="ghost" size="sm">
              View
            </Button>
          </Row>
          <Row label="Diagnostics report">
            <Button variant="ghost" size="sm">
              Export
            </Button>
          </Row>
        </Group>
      </div>

      <div className="mt-6">
        <PrototypeNote>
          Toggles are visual only here; each maps to a persisted preference in the Flutter build.
        </PrototypeNote>
      </div>
    </AppShell>
  );
}

function Group({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="panel p-5">
      <h2 className="mb-1 text-[0.7rem] font-medium uppercase tracking-[0.18em] text-muted-foreground">
        {title}
      </h2>
      <div className="divide-y divide-border">{children}</div>
    </section>
  );
}

function Row({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <div className="flex min-h-14 flex-wrap items-center justify-between gap-3 py-3">
      <div className="min-w-0">
        <p className="text-sm font-medium">{label}</p>
        {hint ? <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p> : null}
      </div>
      {children}
    </div>
  );
}
