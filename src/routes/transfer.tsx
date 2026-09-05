import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useMemo, useState } from "react";
import {
  Archive,
  CheckCircle2,
  File as FileIcon,
  FileText,
  Film,
  Folder,
  Image as ImageIcon,
  Music,
  Pause,
  Play,
  Plus,
  Upload,
  X,
} from "lucide-react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import {
  DevicePairRow,
  PrototypeNote,
  SectionTitle,
  Stat,
  StatusPill,
  TrustNote,
} from "@/components/hyperdrop/primitives";
import { Button } from "@/components/ui/button";
import {
  formatBytes,
  formatDuration,
  formatSpeed,
  pairedDevice,
  selectedFiles,
  thisDevice,
  totalSelectedBytes,
  type FileCategory,
} from "@/lib/hyperdrop";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/transfer")({
  head: () => ({
    meta: [
      { title: "Transfer files — HyperDrop" },
      {
        name: "description",
        content:
          "Pick photos, videos, documents and folders, then stream them straight to the paired device with live speed, queue and resume.",
      },
      { property: "og:title", content: "Transfer files — HyperDrop" },
      {
        property: "og:description",
        content: "Live transfer view with speed, queue, pause and resume — all on your local network.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: TransferScreen,
});

const categories: { key: FileCategory; label: string; icon: typeof ImageIcon; count: number }[] = [
  { key: "photos", label: "Photos", icon: ImageIcon, count: 4128 },
  { key: "videos", label: "Videos", icon: Film, count: 212 },
  { key: "documents", label: "Documents", icon: FileText, count: 863 },
  { key: "audio", label: "Audio", icon: Music, count: 1290 },
  { key: "archives", label: "Archives", icon: Archive, count: 47 },
  { key: "folders", label: "Folders", icon: Folder, count: 19 },
  { key: "other", label: "Other", icon: FileIcon, count: 306 },
];

const TOTAL = 1_820_000_000;

function TransferScreen() {
  const [stage, setStage] = useState<"select" | "sending" | "done">("select");
  const [paused, setPaused] = useState(false);
  const [sent, setSent] = useState(0);
  const [dragging, setDragging] = useState(false);
  const [active, setActive] = useState<FileCategory>("videos");

  useEffect(() => {
    if (stage !== "sending" || paused) return;
    const t = setInterval(() => {
      setSent((s) => {
        const next = s + TOTAL * 0.02;
        if (next >= TOTAL) {
          setStage("done");
          return TOTAL;
        }
        return next;
      });
    }, 160);
    return () => clearInterval(t);
  }, [stage, paused]);

  const pct = Math.min(100, Math.round((sent / TOTAL) * 100));
  const speed = 87_400_000;
  const remaining = useMemo(() => Math.max(0, (TOTAL - sent) / speed), [sent]);

  return (
    <AppShell>
      <header className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-semibold">
            {stage === "select" ? "Send files" : `Sending to ${pairedDevice.name}`}
          </h1>
          <p className="mt-1.5 text-muted-foreground">
            {stage === "select"
              ? "Choose what to send. Large files stream in chunks — nothing is loaded into memory."
              : "Direct local transfer in progress."}
          </p>
        </div>
        <StatusPill tone={stage === "done" ? "success" : "primary"}>
          {stage === "done" ? "Transfer complete" : "Connected securely"}
        </StatusPill>
      </header>

      <div className="panel mb-6 p-5">
        <DevicePairRow
          left={thisDevice}
          right={pairedDevice}
          active={stage === "sending" && !paused}
          label={
            stage === "sending"
              ? paused
                ? "Paused — resumable"
                : `${formatSpeed(speed)} · local Wi-Fi`
              : "Connected securely"
          }
        />
        <div className="mt-5 grid gap-3 sm:grid-cols-4">
          <Stat label="Quality" value="Excellent" hint="−41 dBm · 5 GHz" />
          <Stat label="Est. speed" value="92 MB/s" hint="Measured this session" />
          <Stat label="Transferred" value="3.1 GB" hint="This session" />
          <Stat label="Duration" value="12 min" hint="Since pairing" />
        </div>
      </div>

      {stage === "select" ? (
        <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,0.9fr)]">
          <section className="panel p-5">
            <SectionTitle title="Browse" description="Multi-select across categories" />
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {categories.map((c) => (
                <button
                  key={c.key}
                  type="button"
                  onClick={() => setActive(c.key)}
                  className={cn(
                    "flex min-h-20 flex-col items-start gap-2 rounded-xl border p-3.5 text-left transition-colors",
                    active === c.key
                      ? "border-primary/40 bg-primary/8"
                      : "border-border bg-surface-raised hover:bg-muted",
                  )}
                >
                  <c.icon
                    className={cn("size-5", active === c.key ? "text-primary" : "text-muted-foreground")}
                    aria-hidden
                  />
                  <span className="text-sm font-medium">{c.label}</span>
                  <span className="text-xs text-muted-foreground">{c.count} items</span>
                </button>
              ))}
            </div>

            {/* Windows drag & drop zone */}
            <div
              onDragOver={(e) => {
                e.preventDefault();
                setDragging(true);
              }}
              onDragLeave={() => setDragging(false)}
              onDrop={(e) => {
                e.preventDefault();
                setDragging(false);
              }}
              className={cn(
                "mt-4 hidden flex-col items-center justify-center rounded-xl border-2 border-dashed px-6 py-9 text-center transition-colors lg:flex",
                dragging ? "border-primary bg-primary/8" : "border-border-strong bg-surface-raised",
              )}
            >
              <Upload className="size-6 text-muted-foreground" aria-hidden />
              <p className="mt-2.5 text-sm font-medium">Drop files or folders here</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Or paste with Ctrl+V, or use the Windows file picker
              </p>
              <Button variant="outline" size="sm" className="mt-3">
                <Plus className="size-4" /> Browse files
              </Button>
            </div>
          </section>

          <section className="panel flex flex-col p-5">
            <SectionTitle
              title={`${selectedFiles.length} files selected`}
              description={`Total ${formatBytes(totalSelectedBytes)}`}
            />
            <ul className="flex-1 space-y-1.5">
              {selectedFiles.map((f) => (
                <li
                  key={f.id}
                  className="flex items-center gap-3 rounded-xl border border-border bg-surface-raised px-3 py-2.5"
                >
                  <FileGlyph category={f.category} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-medium">{f.name}</span>
                    <span className="block truncate text-xs text-muted-foreground">
                      {f.relativePath} · {formatBytes(f.bytes)}
                    </span>
                  </span>
                  <Button variant="ghost" size="icon" aria-label={`Remove ${f.name}`}>
                    <X className="size-4" />
                  </Button>
                </li>
              ))}
            </ul>
            <Button
              size="lg"
              className="mt-5 w-full"
              onClick={() => {
                setSent(0);
                setStage("sending");
              }}
            >
              Send {formatBytes(totalSelectedBytes, 1)}
            </Button>
            <p className="mt-3 text-center text-xs text-muted-foreground">
              Sending to {pairedDevice.name}
            </p>
          </section>
        </div>
      ) : stage === "sending" ? (
        <div className="grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(0,0.9fr)]">
          <section className="panel p-6">
            <p className="text-[0.7rem] font-medium uppercase tracking-[0.18em] text-muted-foreground">
              Current file
            </p>
            <div className="mt-2 flex items-baseline justify-between gap-4">
              <h2 className="truncate font-display text-xl font-semibold">Vacation.mp4</h2>
              <span className="code-digits text-3xl font-semibold text-primary">{pct}%</span>
            </div>

            <div
              className="mt-4 h-2.5 w-full overflow-hidden rounded-full bg-muted"
              role="progressbar"
              aria-valuenow={pct}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label="Transfer progress"
            >
              <div
                className="h-full rounded-full bg-[var(--beam)] transition-[width] duration-200"
                style={{ width: `${pct}%` }}
              />
            </div>

            <div className="mt-5 grid gap-3 sm:grid-cols-3">
              <Stat label="Transferred" value={`${formatBytes(sent, 2)}`} hint={`of ${formatBytes(TOTAL)}`} />
              <Stat label="Current speed" value={paused ? "—" : formatSpeed(speed)} hint="Avg 81.2 MB/s" />
              <Stat
                label="Remaining"
                value={paused ? "Paused" : formatDuration(remaining)}
                hint="2 files left"
              />
            </div>

            <div className="mt-6 flex gap-2">
              <Button variant="secondary" className="flex-1" onClick={() => setPaused((p) => !p)}>
                {paused ? <Play className="size-4" /> : <Pause className="size-4" />}
                {paused ? "Resume" : "Pause"}
              </Button>
              <Button variant="outline" className="flex-1" onClick={() => setStage("select")}>
                <X className="size-4" /> Cancel
              </Button>
            </div>
            <div className="mt-4">
              <TrustNote />
            </div>
          </section>

          <section className="panel p-5">
            <SectionTitle title="Queue" description="3 files · chunked & verified" />
            <ul className="space-y-1.5">
              {selectedFiles.map((f, i) => (
                <li
                  key={f.id}
                  className="flex items-center gap-3 rounded-xl border border-border bg-surface-raised px-3 py-2.5"
                >
                  <FileGlyph category={f.category} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-medium">{f.name}</span>
                    <span className="block text-xs text-muted-foreground">
                      {formatBytes(f.bytes)}
                    </span>
                  </span>
                  <StatusPill tone={i === 0 ? "success" : i === 1 ? "primary" : "muted"}>
                    {i === 0 ? "Verified" : i === 1 ? "Sending" : "Queued"}
                  </StatusPill>
                </li>
              ))}
            </ul>
            <PrototypeNote>
              Progress is simulated for design review. The Flutter build reports real chunk
              throughput and SHA-256 verification per file.
            </PrototypeNote>
          </section>
        </div>
      ) : (
        <section className="panel mx-auto max-w-xl p-8 text-center">
          <span className="mx-auto flex size-20 items-center justify-center rounded-full bg-success/12">
            <CheckCircle2 className="size-10 text-success" aria-hidden />
          </span>
          <h2 className="mt-5 font-display text-2xl font-semibold">Transfer complete</h2>
          <p className="mt-1.5 text-muted-foreground">
            1.82 GB transferred · 3 files · 21.4 seconds
          </p>
          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            <Stat label="Average" value="85.1 MB/s" />
            <Stat label="Integrity" value="3/3 verified" />
            <Stat label="Retries" value="0" />
          </div>
          <div className="mt-7 grid gap-2 sm:grid-cols-2">
            <Button size="lg">Open files</Button>
            <Button size="lg" variant="secondary" onClick={() => setStage("select")}>
              Send more
            </Button>
            <Button variant="outline">View transfer details</Button>
            <Button variant="ghost" onClick={() => setStage("select")}>
              Done
            </Button>
          </div>
        </section>
      )}
    </AppShell>
  );
}

function FileGlyph({ category }: { category: FileCategory }) {
  const map: Record<FileCategory, typeof ImageIcon> = {
    photos: ImageIcon,
    videos: Film,
    documents: FileText,
    audio: Music,
    archives: Archive,
    folders: Folder,
    other: FileIcon,
  };
  const Icon = map[category];
  return (
    <span className="flex size-9 shrink-0 items-center justify-center rounded-lg border border-border bg-background text-muted-foreground">
      <Icon className="size-4" aria-hidden />
    </span>
  );
}
