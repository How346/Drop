import { createFileRoute, Link } from "@tanstack/react-router";
import { useState } from "react";
import { ArrowDownLeft, ArrowUpRight, Inbox, RotateCcw, Trash2 } from "lucide-react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import { PrototypeNote, StatusPill } from "@/components/hyperdrop/primitives";
import { Button } from "@/components/ui/button";
import { formatBytes, history } from "@/lib/hyperdrop";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/history")({
  head: () => ({
    meta: [
      { title: "Transfer history — HyperDrop" },
      {
        name: "description",
        content:
          "A local-only log of every send and receive: file, device, size, time and status. Nothing is synced anywhere.",
      },
      { property: "og:title", content: "Transfer history — HyperDrop" },
      {
        property: "og:description",
        content: "Local transfer history with resume for interrupted sends.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: HistoryScreen,
});

const filters = ["All", "Sent", "Received", "Failed"] as const;

function HistoryScreen() {
  const [filter, setFilter] = useState<(typeof filters)[number]>("All");
  const [cleared, setCleared] = useState(false);

  const items = cleared
    ? []
    : history.filter((h) =>
        filter === "All"
          ? true
          : filter === "Failed"
            ? h.status !== "completed"
            : filter === "Sent"
              ? h.direction === "sent"
              : h.direction === "received",
      );

  return (
    <AppShell>
      <header className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-semibold">Transfer history</h1>
          <p className="mt-1.5 text-muted-foreground">Stored on this device only.</p>
        </div>
        <Button variant="outline" size="sm" onClick={() => setCleared(true)}>
          <Trash2 className="size-4" /> Clear history
        </Button>
      </header>

      <div className="mb-5 flex flex-wrap gap-2">
        {filters.map((f) => (
          <button
            key={f}
            type="button"
            onClick={() => setFilter(f)}
            className={cn(
              "rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors",
              filter === f
                ? "border-primary/40 bg-primary/10 text-primary"
                : "border-border bg-surface text-muted-foreground hover:bg-muted",
            )}
          >
            {f}
          </button>
        ))}
      </div>

      {items.length === 0 ? (
        <section className="panel flex flex-col items-center px-6 py-16 text-center">
          <span className="flex size-16 items-center justify-center rounded-2xl border border-border bg-surface-raised">
            <Inbox className="size-7 text-muted-foreground" aria-hidden />
          </span>
          <h2 className="mt-5 font-display text-xl font-semibold">No transfers yet</h2>
          <p className="mt-1.5 max-w-sm text-sm text-muted-foreground">
            Send your first file to see it here. History never leaves this device.
          </p>
          <Button asChild className="mt-5">
            <Link to="/transfer">Send a file</Link>
          </Button>
        </section>
      ) : (
        <ul className="panel divide-y divide-border overflow-hidden p-0">
          {items.map((h) => (
            <li key={h.id} className="flex items-center gap-4 px-4 py-4 sm:px-5">
              <span
                className={cn(
                  "flex size-10 shrink-0 items-center justify-center rounded-xl border",
                  h.direction === "sent"
                    ? "border-primary/25 bg-primary/10 text-primary"
                    : "border-accent/30 bg-accent/10 text-accent",
                )}
                aria-hidden
              >
                {h.direction === "sent" ? (
                  <ArrowUpRight className="size-5" />
                ) : (
                  <ArrowDownLeft className="size-5" />
                )}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium">{h.fileName}</p>
                <p className="truncate text-sm text-muted-foreground">
                  {h.direction === "sent" ? "Sent to" : "Received from"} {h.deviceName} ·{" "}
                  {formatBytes(h.bytes)}
                </p>
                {h.note ? <p className="mt-0.5 text-xs text-warning">{h.note}</p> : null}
              </div>
              <div className="hidden text-right text-sm text-muted-foreground sm:block">
                {h.at}
              </div>
              <div className="flex items-center gap-2">
                {h.status === "completed" ? (
                  <StatusPill tone="success">Completed</StatusPill>
                ) : h.status === "failed" ? (
                  <>
                    <StatusPill tone="danger">Failed</StatusPill>
                    <Button variant="ghost" size="icon" aria-label="Resume transfer">
                      <RotateCcw className="size-4" />
                    </Button>
                  </>
                ) : (
                  <StatusPill tone="muted">Cancelled</StatusPill>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}

      <div className="mt-5">
        <PrototypeNote>History is seeded sample data for design review.</PrototypeNote>
      </div>
    </AppShell>
  );
}
