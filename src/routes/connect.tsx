import { createFileRoute, Link } from "@tanstack/react-router";
import { useState } from "react";
import { AlertCircle, ArrowRight, Delete, Loader2, ShieldCheck } from "lucide-react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import {
  DeviceGlyph,
  PrototypeNote,
  SectionTitle,
  TrustNote,
} from "@/components/hyperdrop/primitives";
import { Button } from "@/components/ui/button";
import { recentDevices } from "@/lib/hyperdrop";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/connect")({
  head: () => ({
    meta: [
      { title: "Connect to a device — HyperDrop" },
      {
        name: "description",
        content:
          "Enter a 6-digit HyperDrop code to pair two devices over your local network. No accounts, no cloud, no IP addresses.",
      },
      { property: "og:title", content: "Connect to a device — HyperDrop" },
      {
        property: "og:description",
        content: "Pair Android and Windows devices with a short-lived 6-digit code.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: ConnectScreen,
});

type Phase = "idle" | "connecting" | "invalid" | "notfound";



function ConnectScreen() {
  const [digits, setDigits] = useState("");
  const [phase, setPhase] = useState<Phase>("idle");

  const push = (d: string) => {
    setPhase("idle");
    setDigits((v) => (v + d).slice(0, 6));
  };
  const back = () => {
    setPhase("idle");
    setDigits((v) => v.slice(0, -1));
  };

  const connect = () => {
    if (digits.length < 6) return;
    setPhase("connecting");
    setTimeout(() => setPhase(digits === "482731" ? "connecting" : "notfound"), 1400);
  };

  return (
    <AppShell>
      <header className="mb-8">
        <h1 className="font-display text-3xl font-semibold">Connect to device</h1>
        <p className="mt-1.5 text-muted-foreground">
          Ask for the 6-digit code shown on the other device.
        </p>
      </header>

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,0.85fr)]">
        <section className="panel p-6 sm:p-8">
          <label
            htmlFor="hd-code"
            className="text-[0.7rem] font-medium uppercase tracking-[0.18em] text-muted-foreground"
          >
            Enter 6-digit code
          </label>

          <div className="mt-4 flex gap-2 sm:gap-3" aria-hidden>
            {Array.from({ length: 6 }).map((_, i) => (
              <span
                key={i}
                className={cn(
                  "flex h-16 flex-1 items-center justify-center rounded-xl border text-2xl font-semibold sm:h-20 sm:text-3xl",
                  "code-digits tabular-nums",
                  i === 2 && "mr-2 sm:mr-4",
                  digits.length === i
                    ? "border-primary bg-primary/5 text-foreground"
                    : "border-border bg-surface-raised",
                  phase === "invalid" || phase === "notfound"
                    ? "border-destructive/50 bg-destructive/5"
                    : "",
                )}
              >
                {digits[i] ?? ""}
              </span>
            ))}
          </div>

          {/* Windows: plain numeric input. Android: keypad below. */}
          <input
            id="hd-code"
            inputMode="numeric"
            autoComplete="one-time-code"
            pattern="[0-9]*"
            maxLength={6}
            value={digits}
            onChange={(e) => {
              setPhase("idle");
              setDigits(e.target.value.replace(/\D/g, "").slice(0, 6));
            }}
            placeholder="482731"
            aria-label="Enter 6-digit connection code"
            className="mt-4 hidden h-11 w-full rounded-xl border border-input bg-surface-raised px-4 font-mono text-lg tracking-[0.3em] outline-none placeholder:text-muted-foreground/50 focus-visible:border-ring lg:block"
          />

          {phase === "notfound" ? (
            <p className="mt-4 flex items-start gap-2 text-sm text-destructive">
              <AlertCircle className="mt-0.5 size-4 shrink-0" />
              <span>
                <span className="font-medium">Device not found.</span> That code isn't active on
                this network. Check the digits, or ask for a fresh code.
              </span>
            </p>
          ) : null}

          <Button
            size="lg"
            className="mt-6 w-full"
            disabled={digits.length < 6 || phase === "connecting"}
            onClick={connect}
          >
            {phase === "connecting" ? (
              <>
                <Loader2 className="size-4 animate-spin" /> Connecting…
              </>
            ) : (
              <>
                Connect <ArrowRight className="size-4" />
              </>
            )}
          </Button>

          {/* Numeric keypad — touch layout */}
          <div className="mt-6 grid grid-cols-3 gap-2 lg:hidden">
            {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((d) => (
              <KeypadKey key={d} onClick={() => push(d)}>
                {d}
              </KeypadKey>
            ))}
            <span />
            <KeypadKey onClick={() => push("0")}>0</KeypadKey>
            <KeypadKey onClick={back} label="Delete last digit">
              <Delete className="size-5" />
            </KeypadKey>
          </div>

          <div className="mt-7 rounded-xl border border-border bg-surface-raised p-4">
            <p className="text-sm font-medium">Waiting for another device?</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Share your own code instead and let them connect to you.
            </p>
            <Button asChild variant="outline" size="sm" className="mt-3">
              <Link to="/">Show my code</Link>
            </Button>
          </div>
        </section>

        <section className="space-y-6">
          <div className="panel p-5">
            <SectionTitle title="Recent devices" description="Stored locally on this device" />
            <ul className="space-y-1.5">
              {recentDevices
                .filter((d) => !d.blocked)
                .map((d) => (
                  <li
                    key={d.id}
                    className="flex items-center gap-3 rounded-xl px-2 py-2.5 hover:bg-muted"
                  >
                    <DeviceGlyph kind={d.kind} size="sm" />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-medium">{d.name}</span>
                      <span className="block truncate text-xs text-muted-foreground">
                        {d.platform} · {d.lastConnected}
                      </span>
                    </span>
                    <Button variant="ghost" size="sm">
                      Reconnect
                    </Button>
                  </li>
                ))}
            </ul>
          </div>

          <div className="panel p-5">
            <div className="flex items-start gap-3">
              <ShieldCheck className="mt-0.5 size-5 text-success" />
              <div>
                <p className="font-medium">How pairing stays safe</p>
                <ul className="mt-2 space-y-1.5 text-sm text-muted-foreground">
                  <li>Codes are short-lived and rotate every 5 minutes.</li>
                  <li>The other device must explicitly accept the request.</li>
                  <li>The session key is negotiated device-to-device.</li>
                  <li>IP addresses are never shown — only device names.</li>
                </ul>
                <div className="mt-3">
                  <TrustNote />
                </div>
              </div>
            </div>
          </div>

          <PrototypeNote>
            Try <span className="code-digits">482 731</span> for the success path, any other code
            for the error state.
          </PrototypeNote>
        </section>
      </div>
    </AppShell>
  );
}

function KeypadKey({
  children,
  onClick,
  label,
}: {
  children: React.ReactNode;
  onClick: () => void;
  label?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label ?? undefined}
      className="flex h-14 items-center justify-center rounded-xl border border-border bg-surface-raised font-display text-xl font-medium transition-colors active:bg-muted"
    >
      {children}
    </button>
  );
}
