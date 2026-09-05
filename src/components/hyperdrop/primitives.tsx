import type { ReactNode } from "react";
import {
  Laptop,
  Monitor,
  Smartphone,
  Tablet,
  ShieldCheck,
  WifiOff,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { Device, DeviceKind } from "@/lib/hyperdrop";

export const deviceIcons: Record<DeviceKind, LucideIcon> = {
  "android-phone": Smartphone,
  "android-tablet": Tablet,
  "windows-desktop": Monitor,
  "windows-laptop": Laptop,
};

export function DeviceGlyph({
  kind,
  size = "md",
  tone = "neutral",
  className,
}: {
  kind: DeviceKind;
  size?: "sm" | "md" | "lg";
  tone?: "neutral" | "primary" | "accent";
  className?: string;
}) {
  const Icon = deviceIcons[kind];
  return (
    <span
      className={cn(
        "inline-flex items-center justify-center rounded-2xl border",
        size === "sm" && "size-9 rounded-xl",
        size === "md" && "size-12",
        size === "lg" && "size-20 rounded-3xl",
        tone === "neutral" && "border-border bg-surface-raised text-foreground",
        tone === "primary" && "border-primary/30 bg-primary/10 text-primary",
        tone === "accent" && "border-accent/35 bg-accent/10 text-accent",
        className,
      )}
      aria-hidden
    >
      <Icon className={cn(size === "lg" ? "size-9" : size === "md" ? "size-5" : "size-4")} />
    </span>
  );
}

export function SectionTitle({
  title,
  description,
  action,
}: {
  title: string;
  description?: string | undefined;
  action?: ReactNode | undefined;
}) {
  return (
    <div className="mb-4 flex items-end justify-between gap-4">
      <div>
        <h2 className="text-lg font-semibold">{title}</h2>
        {description ? (
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        ) : null}
      </div>
      {action}
    </div>
  );
}

export function Stat({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint?: string | undefined;
}) {
  return (
    <div className="rounded-xl border border-border bg-surface-raised px-4 py-3">
      <p className="text-[0.7rem] font-medium uppercase tracking-[0.14em] text-muted-foreground">
        {label}
      </p>
      <p className="mt-1.5 font-display text-lg font-semibold tabular-nums">{value}</p>
      {hint ? <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p> : null}
    </div>
  );
}

export function StatusPill({
  children,
  tone = "success",
}: {
  children: ReactNode;
  tone?: "success" | "muted" | "warning" | "danger" | "primary";
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium",
        tone === "success" && "border-success/30 bg-success/10 text-success",
        tone === "primary" && "border-primary/30 bg-primary/10 text-primary",
        tone === "muted" && "border-border bg-muted text-muted-foreground",
        tone === "warning" && "border-warning/35 bg-warning/10 text-warning",
        tone === "danger" && "border-destructive/30 bg-destructive/10 text-destructive",
      )}
    >
      {children}
    </span>
  );
}

export function LiveDot({ tone = "success" }: { tone?: "success" | "warning" | "danger" }) {
  return (
    <span className="relative inline-flex size-2">
      <span
        className={cn(
          "hd-ring absolute inset-0 rounded-full",
          tone === "success" && "bg-success",
          tone === "warning" && "bg-warning",
          tone === "danger" && "bg-destructive",
        )}
      />
      <span
        className={cn(
          "relative size-2 rounded-full",
          tone === "success" && "bg-success",
          tone === "warning" && "bg-warning",
          tone === "danger" && "bg-destructive",
        )}
      />
    </span>
  );
}

/** Animated beam between two devices — the core brand metaphor. */
export function DataBeam({
  active = true,
  label,
}: {
  active?: boolean;
  label?: string | undefined;
}) {
  return (
    <div className="relative flex-1">
      <div className="relative h-[3px] w-full overflow-hidden rounded-full bg-border">
        {active ? (
          <span className="hd-beam absolute inset-y-0 left-0 w-1/3 rounded-full bg-[var(--beam)]" />
        ) : null}
      </div>
      {label ? (
        <p className="mt-2 text-center text-xs text-muted-foreground">{label}</p>
      ) : null}
    </div>
  );
}

export function DevicePairRow({
  left,
  right,
  active = true,
  label,
}: {
  left: Device;
  right: Device;
  active?: boolean;
  label?: string | undefined;
}) {
  return (
    <div className="flex items-center gap-4">
      <DevicePill device={left} tone="primary" />
      <DataBeam active={active} label={label} />
      <DevicePill device={right} tone="accent" align="right" />
    </div>
  );
}

function DevicePill({
  device,
  tone,
  align = "left",
}: {
  device: Device;
  tone: "primary" | "accent";
  align?: "left" | "right";
}) {
  return (
    <div
      className={cn(
        "flex min-w-0 items-center gap-3",
        align === "right" && "flex-row-reverse text-right",
      )}
    >
      <DeviceGlyph kind={device.kind} tone={tone} className="hd-float shrink-0" />
      <div className="min-w-0">
        <p className="truncate text-sm font-medium">{device.name}</p>
        <p className="truncate text-xs text-muted-foreground">{device.platform}</p>
      </div>
    </div>
  );
}

export function TrustNote() {
  return (
    <div className="flex flex-wrap gap-x-5 gap-y-2 text-xs text-muted-foreground">
      <span className="inline-flex items-center gap-1.5">
        <ShieldCheck className="size-3.5 text-success" /> Direct local connection
      </span>
      <span className="inline-flex items-center gap-1.5">
        <WifiOff className="size-3.5 text-accent" /> Internet not required
      </span>
    </div>
  );
}

export function PrototypeNote({ children }: { children: ReactNode }) {
  return (
    <p className="rounded-lg border border-dashed border-border-strong bg-muted/50 px-3 py-2 text-xs text-muted-foreground">
      <span className="font-medium text-foreground">Prototype only · </span>
      {children}
    </p>
  );
}
