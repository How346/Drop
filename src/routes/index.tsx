import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import {
  ArrowRight,
  Check,
  Copy,
  Download,
  RefreshCw,
  ShieldCheck,
  Upload,
  X,
} from "lucide-react";
import { AppShell } from "@/components/hyperdrop/app-shell";
import {
  DeviceGlyph,
  LiveDot,
  PrototypeNote,
  SectionTitle,
  StatusPill,
  TrustNote,
} from "@/components/hyperdrop/primitives";
import { Button } from "@/components/ui/button";
import { recentDevices, thisDevice } from "@/lib/hyperdrop";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "HyperDrop — Offline High-Speed File Transfer" },
      {
        name: "description",
        content:
          "Pick files, connect with a 6-digit code, send at high speed. HyperDrop moves files directly between Android and Windows with no cloud and no internet.",
      },
      { property: "og:title", content: "HyperDrop — Offline High-Speed File Transfer" },
      {
        property: "og:description",
        content:
          "Direct device-to-device transfers over local Wi-Fi. No account, no cloud, no internet required.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: HomeScreen,
});

const CODE = "482731";
const CODE_TTL = 296;

function HomeScreen() {
  const [copied, setCopied] = useState(false);
  const [remaining, setRemaining] = useState(CODE_TTL);
  const [request, setRequest] = useState<"pending" | "accepted" | "declined">("pending");

  useEffect(() => {
    const t = setInterval(() => setRemaining((r) => (r > 0 ? r - 1 : CODE_TTL)), 1000);
    return () => clearInterval(t);
  }, []);

  const mins = Math.floor(remaining / 60);
  const secs = (remaining % 60).toString().padStart(2, "0");

  return (
    <AppShell>
      <header className="mb-8">
        <h1 className="font-display text-3xl font-semibold sm:text-4xl">HyperDrop</h1>
        <p className="mt-1.5 text-muted-foreground">Fast. Private. Offline.</p>
      </header>

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1.35fr)_minmax(0,1fr)]">
        {/* Connection code card */}
        <section className="panel grid-field relative overflow-hidden p-6 sm:p-8">
          <div
            className="pointer-events-none absolute -right-24 -top-24 size-64 rounded-full bg-primary/15 blur-3xl"
            aria-hidden
          />
          <div className="relative">
            <div className="flex items-center justify-between gap-3">
              <p className="text-[0.7rem] font-medium uppercase tracking-[0.18em] text-muted-foreground">
                Your code
              </p>
              <StatusPill tone="success">
                <LiveDot /> Ready to connect
              </StatusPill>
            </div>

            <p
              className="code-digits mt-5 text-5xl font-semibold sm:text-[4.25rem] sm:leading-[1.05]"
              aria-label="Connection code 4 8 2 7 3 1"
            >
              482 731
            </p>

            <div className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-muted-foreground">
              <span>
                Expires in{" "}
                <span className="font-mono tabular-nums text-foreground">
                  {mins}:{secs}
                </span>
              </span>
              <span className="hidden h-3 w-px bg-border sm:block" aria-hidden />
              <span>
                This device: <span className="text-foreground">{thisDevice.name}</span>
              </span>
            </div>

            <div className="mt-6 flex flex-wrap gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setCopied(true);
                  setTimeout(() => setCopied(false), 1600);
                }}
              >
                {copied ? <Check className="size-4" /> : <Copy className="size-4" />}
                {copied ? "Copied" : "Copy code"}
              </Button>
              <Button variant="ghost" size="sm" onClick={() => setRemaining(CODE_TTL)}>
                <RefreshCw className="size-4" /> New code
              </Button>
            </div>

            <div className="mt-7 grid gap-2.5 sm:grid-cols-3">
              <Button asChild size="lg" className="justify-center">
                <Link to="/connect">Connect to device</Link>
              </Button>
              <Button asChild size="lg" variant="secondary" className="justify-center">
                <Link to="/transfer">
                  <Upload className="size-4" /> Send files
                </Link>
              </Button>
              <Button asChild size="lg" variant="secondary" className="justify-center">
                <Link to="/transfer">
                  <Download className="size-4" /> Receive files
                </Link>
              </Button>
            </div>

            <div className="mt-6 border-t border-border pt-4">
              <TrustNote />
            </div>
          </div>
        </section>

        {/* Incoming request */}
        <section className="space-y-6">
          <div className="panel p-5">
            <SectionTitle title="Incoming request" />
            {request === "pending" ? (
              <div>
                <div className="flex items-center gap-4">
                  <DeviceGlyph kind="windows-laptop" size="lg" tone="primary" />
                  <div className="min-w-0">
                    <p className="font-display text-lg font-semibold">Alex's Laptop</p>
                    <p className="text-sm text-muted-foreground">Windows PC · wants to connect</p>
                    <p className="code-digits mt-1 text-sm text-muted-foreground">482 731</p>
                  </div>
                </div>
                <div className="mt-5 flex gap-2">
                  <Button className="flex-1" onClick={() => setRequest("accepted")}>
                    <Check className="size-4" /> Accept
                  </Button>
                  <Button
                    variant="outline"
                    className="flex-1"
                    onClick={() => setRequest("declined")}
                  >
                    <X className="size-4" /> Decline
                  </Button>
                </div>
                <div className="mt-4">
                  <TrustNote />
                </div>
              </div>
            ) : (
              <div className="flex items-start gap-3">
                <ShieldCheck
                  className={cn(
                    "mt-0.5 size-5",
                    request === "accepted" ? "text-success" : "text-muted-foreground",
                  )}
                />
                <div>
                  <p className="font-medium">
                    {request === "accepted" ? "Paired for this session" : "Request declined"}
                  </p>
                  <p className="mt-1 text-sm text-muted-foreground">
                    {request === "accepted"
                      ? "Alex's Laptop is connected securely over your local network."
                      : "Alex's Laptop was not allowed to connect. Nothing was transferred."}
                  </p>
                  <Button
                    variant="link"
                    className="mt-1 h-auto p-0"
                    onClick={() => setRequest("pending")}
                  >
                    Reset demo
                  </Button>
                </div>
              </div>
            )}
          </div>

          <div className="panel p-5">
            <SectionTitle title="Nearby devices" description="Found on Home-5G" />
            <ul className="space-y-1.5">
              {recentDevices.slice(0, 3).map((d) => (
                <li key={d.id}>
                  <Link
                    to="/connect"
                    className="flex items-center gap-3 rounded-xl px-2 py-2.5 transition-colors hover:bg-muted"
                  >
                    <DeviceGlyph kind={d.kind} size="sm" />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-medium">{d.name}</span>
                      <span className="block truncate text-xs text-muted-foreground">
                        {d.platform} · {d.trusted ? "Trusted" : "Not trusted"}
                      </span>
                    </span>
                    <ArrowRight className="size-4 text-muted-foreground" aria-hidden />
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <PrototypeNote>
            Codes, devices and progress shown here are reference UI. Discovery, pairing and
            transfer run natively in the Flutter build.
          </PrototypeNote>
        </section>
      </div>
    </AppShell>
  );
}
