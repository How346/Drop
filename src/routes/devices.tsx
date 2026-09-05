import { createFileRoute } from "@tanstack/react-router";
import { Ban, Pencil, Trash2 } from "lucide-react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import {
  DeviceGlyph,
  DevicePairRow,
  PrototypeNote,
  SectionTitle,
  Stat,
  StatusPill,
  TrustNote,
} from "@/components/hyperdrop/primitives";
import { Button } from "@/components/ui/button";
import { pairedDevice, recentDevices, thisDevice } from "@/lib/hyperdrop";

export const Route = createFileRoute("/devices")({
  head: () => ({
    meta: [
      { title: "Connected & recent devices — HyperDrop" },
      {
        name: "description",
        content:
          "See the live pairing, connection quality and every device you've transferred with. Rename, remove or block — all stored locally.",
      },
      { property: "og:title", content: "Connected & recent devices — HyperDrop" },
      {
        property: "og:description",
        content: "Manage paired and remembered devices by name, never by IP address.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: DevicesScreen,
});

function DevicesScreen() {
  return (
    <AppShell>
      <header className="mb-6">
        <h1 className="font-display text-3xl font-semibold">Devices</h1>
        <p className="mt-1.5 text-muted-foreground">
          Everything is identified by name — HyperDrop never shows IP addresses.
        </p>
      </header>

      <section className="panel mb-6 p-6">
        <div className="mb-5 flex items-center justify-between gap-3">
          <h2 className="text-lg font-semibold">Connected now</h2>
          <StatusPill tone="success">Connected securely</StatusPill>
        </div>
        <DevicePairRow left={thisDevice} right={pairedDevice} label="Encrypted local session" />
        <div className="mt-6 grid gap-3 sm:grid-cols-4">
          <Stat label="Quality" value="Excellent" hint="5 GHz · −41 dBm" />
          <Stat label="Est. speed" value="92 MB/s" />
          <Stat label="Total transferred" value="3.1 GB" hint="12 files" />
          <Stat label="Duration" value="12:04" hint="Since pairing" />
        </div>
        <div className="mt-6 flex flex-wrap gap-2">
          <Button>Send files</Button>
          <Button variant="secondary">Receive files</Button>
          <Button variant="outline">Browse transfers</Button>
          <Button variant="ghost" className="text-destructive hover:text-destructive">
            Disconnect
          </Button>
        </div>
        <div className="mt-5 border-t border-border pt-4">
          <TrustNote />
        </div>
      </section>

      <section className="panel p-5">
        <SectionTitle title="Recent devices" description="Remembered locally, no account needed" />
        <ul className="divide-y divide-border">
          {recentDevices.map((d) => (
            <li key={d.id} className="flex flex-wrap items-center gap-3 py-3">
              <DeviceGlyph kind={d.kind} size="sm" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{d.name}</p>
                <p className="truncate text-xs text-muted-foreground">
                  {d.platform} · Last connected {d.lastConnected}
                </p>
              </div>
              {d.blocked ? (
                <StatusPill tone="danger">Blocked</StatusPill>
              ) : d.trusted ? (
                <StatusPill tone="success">Trusted</StatusPill>
              ) : (
                <StatusPill tone="muted">Ask each time</StatusPill>
              )}
              <div className="flex gap-1">
                <Button variant="ghost" size="icon" aria-label={`Rename ${d.name}`}>
                  <Pencil className="size-4" />
                </Button>
                <Button variant="ghost" size="icon" aria-label={`Block ${d.name}`}>
                  <Ban className="size-4" />
                </Button>
                <Button variant="ghost" size="icon" aria-label={`Remove ${d.name}`}>
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </li>
          ))}
        </ul>
      </section>

      <div className="mt-5">
        <PrototypeNote>
          Device list is sample data. In the Flutter build this comes from local mDNS/UDP discovery
          plus an on-device trust store.
        </PrototypeNote>
      </div>
    </AppShell>
  );
}
