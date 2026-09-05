import { createFileRoute } from "@tanstack/react-router";
import type { ReactNode } from "react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import { PrototypeNote } from "@/components/hyperdrop/primitives";

export const Route = createFileRoute("/spec")({
  head: () => ({
    meta: [
      { title: "Implementation spec — HyperDrop for Flutter" },
      {
        name: "description",
        content:
          "Architecture, transfer protocol layers, error taxonomy, platform abstractions, accessibility and test strategy for building HyperDrop in Flutter for Android and Windows.",
      },
      { property: "og:title", content: "Implementation spec — HyperDrop for Flutter" },
      {
        property: "og:description",
        content: "Clean-architecture guidance and an offline peer-to-peer transfer protocol design.",
      },
      { property: "og:type", content: "article" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: SpecScreen,
});

function SpecScreen() {
  return (
    <AppShell>
      <header className="mb-8 max-w-3xl">
        <h1 className="font-display text-3xl font-semibold">Implementation spec</h1>
        <p className="mt-1.5 text-muted-foreground">
          What the Flutter/Dart build must own. This web app is the interaction reference; the
          production transfer path is native, local and offline.
        </p>
      </header>

      <div className="grid gap-6 lg:grid-cols-2">
        <Block title="Protocol layers">
          <Pre>{`Discovery        mDNS/Bonjour + UDP broadcast on the local subnet
      ↓          advertises: deviceName, deviceKind, codeHash, protoVersion
Pairing          6-digit code -> short-lived session identity (TTL 5 min)
      ↓          receiver must explicitly Accept; codes are never reused
Secure session   X25519 key agreement -> AES-256-GCM stream, per-session key
      ↓          code is bound into the transcript hash (MITM resistance)
Negotiation      manifest exchange: files, sizes, chunkSize, resume offsets
      ↓
Chunk streaming  ordered chunks, backpressure via credit window
      ↓
Verification     per-chunk CRC + per-file SHA-256 compared to manifest
      ↓
Completion       receiver commits temp -> final path, sends ACK + summary`}</Pre>
        </Block>

        <Block title="Transfer descriptor">
          <Pre>{`Transfer {
  transferId      UUID v4
  sessionId       UUID v4
  fileName        sanitized, no separators or control chars
  relativePath    normalized, rejects '..', absolute and UNC paths
  mimeType        sniffed + extension cross-check
  sizeBytes       int64
  sha256          hex digest of full file
  chunkSize       1 MiB default, negotiated 256 KiB – 8 MiB
  sourceDevice    deviceId + display name
  targetDevice    deviceId + display name
  createdAt       UTC timestamp
  resumeOffset    int64, byte-aligned to chunkSize
}`}</Pre>
        </Block>

        <Block title="Flutter architecture">
          <Pre>{`lib/
  presentation/   screens, widgets, design tokens, routing (GoRouter)
  domain/         entities, value objects, use cases, failures
  data/           repositories, local persistence (Isar/Drift), settings
  network/        discovery, pairing, session crypto, chunk streaming
  platform/       PlatformCapabilities abstraction + Android/Windows impls
  di/             providers (Riverpod), composition root`}</Pre>
          <List
            items={[
              "Riverpod for state; immutable freezed models; repository pattern.",
              "Networking runs in isolates so the UI thread never blocks on I/O.",
              "UI depends on domain only — never on socket or platform types.",
              "Every use case returns Result<T, TransferFailure>; no thrown strings in UI.",
            ]}
          />
        </Block>

        <Block title="Performance rules">
          <List
            items={[
              "Stream with RandomAccessFile + Stream<List<int>>; never read a whole file into RAM.",
              "Fixed reusable buffers per stream; target 1 MiB chunks with 8-chunk credit window.",
              "Hash incrementally while streaming — no second full-file pass.",
              "Concurrency limited to N=3 files; large single files get the full pipe.",
              "Write to a .part temp file, fsync, then atomic rename on verify success.",
              "Resume reads the .part length, rewinds to the last verified chunk boundary.",
            ]}
          />
        </Block>

        <Block title="Platform abstraction">
          <List
            items={[
              "Android: NEARBY_WIFI_DEVICES / ACCESS_FINE_LOCATION prompts, scoped storage via SAF, foreground service + progress notification for long transfers, Wi-Fi Direct where available, lifecycle-safe socket teardown.",
              "Windows: native file picker and save-location dialog, drag-and-drop for files and folders, clipboard paste, resizable window with a 900×600 minimum, navigation rail layout, no-sleep request during active transfers, MSIX packaging.",
              "Shared PlatformCapabilities interface reports: canWifiDirect, canHotspot, canBackgroundTransfer, storageModel. UI degrades from capability flags, never from platform checks.",
            ]}
          />
        </Block>

        <Block title="Error taxonomy">
          <Pre>{`invalidCode         "That code isn't right. Check the six digits."
expiredCode         "This code expired. Ask for a new one."
deviceNotFound      "We couldn't find that device on this network."
rejected            "The other device declined the connection."
connectionLost      "Connection lost. The other device went offline." [Retry]
wifiUnavailable     "Wi-Fi is off. Turn it on or start a hotspot."
permissionDenied    "HyperDrop needs local network access." [Open settings]
insufficientStorage "Not enough space for 1.82 GB." [Choose location]
fileAccessDenied    "That file couldn't be read."
unsupportedFile     "This file type can't be sent."
interrupted         "Transfer paused. Resume when reconnected." [Resume]
checksumMismatch    "A file arrived damaged. Retry that file." [Retry]
destinationMissing  "The save folder is unavailable." [Choose location]
duplicateFile       "A file with this name exists." [Keep both / Replace]
cancelled           "Transfer cancelled. Partial files removed."`}</Pre>
          <p className="mt-3 text-sm text-muted-foreground">
            Raw exceptions are logged to the diagnostics buffer only — never surfaced to users.
          </p>
        </Block>

        <Block title="Security invariants">
          <List
            items={[
              "No file byte ever touches a remote server; there is no backend in the transfer path.",
              "Unknown devices cannot push files — acceptance is explicit unless the device is trusted.",
              "Codes are short-lived, single-session, rate-limited (5 wrong attempts = 60 s lockout).",
              "Filenames and relative paths are normalized and rejected on traversal, absolute paths or reserved Windows names.",
              "Received files are written inside the chosen save root only; overwrite requires user choice.",
              "Disconnect is instant and tears down keys; block-list is enforced at the discovery layer.",
            ]}
          />
        </Block>

        <Block title="Accessibility & responsiveness">
          <List
            items={[
              "Semantic labels on every control; the code is announced digit by digit.",
              "Full keyboard navigation and visible focus rings on Windows.",
              "Touch targets ≥ 48 dp; layouts survive 200% text scale.",
              "High-contrast and reduced-motion modes honored from the system.",
              "Android: phone portrait/landscape and tablet two-pane. Windows: navigation rail, never a stretched phone layout.",
            ]}
          />
        </Block>

        <Block title="Test strategy">
          <List
            items={[
              "Unit: code generation/expiry, path sanitization, chunk math, resume offsets, byte formatting.",
              "Networking: loopback discovery, pairing handshake, MITM/replay rejection, disconnect mid-stream.",
              "Integrity: multi-GB streaming with induced corruption and truncation; checksum must fail closed.",
              "UI: golden tests for every screen in light/dark, plus each error state.",
              "No fake progress, no simulated networking and no hardcoded secrets in the shipped build.",
            ]}
          />
        </Block>
      </div>

      <div className="mt-6 max-w-3xl">
        <PrototypeNote>
          The screens in this app are a design reference. Anything shown as live data here —
          discovery, codes, speeds, progress — must be backed by the real native implementation
          before shipping.
        </PrototypeNote>
      </div>
    </AppShell>
  );
}

function Block({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="panel p-5 sm:p-6">
      <h2 className="mb-4 text-lg font-semibold">{title}</h2>
      {children}
    </section>
  );
}

function Pre({ children }: { children: string }) {
  return (
    <pre className="overflow-x-auto rounded-xl border border-border bg-surface-raised p-4 font-mono text-xs leading-relaxed text-muted-foreground">
      {children}
    </pre>
  );
}

function List({ items }: { items: string[] }) {
  return (
    <ul className="mt-3 space-y-2 text-sm text-muted-foreground">
      {items.map((t) => (
        <li key={t} className="flex gap-2.5">
          <span className="mt-2 size-1.5 shrink-0 rounded-full bg-primary" aria-hidden />
          <span>{t}</span>
        </li>
      ))}
    </ul>
  );
}
