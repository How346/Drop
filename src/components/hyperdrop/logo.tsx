import { cn } from "@/lib/utils";

/** HyperDrop mark: two device slabs joined by a high-speed data beam. */
export function HyperDropMark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 48 48"
      role="img"
      aria-label="HyperDrop"
      className={cn("h-8 w-8", className)}
    >
      <defs>
        <linearGradient id="hd-beam-grad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="var(--color-primary)" />
          <stop offset="100%" stopColor="var(--color-accent)" />
        </linearGradient>
      </defs>
      <rect
        x="3"
        y="9"
        width="11"
        height="30"
        rx="3.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.6"
      />
      <rect
        x="34"
        y="14"
        width="11"
        height="20"
        rx="2.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.6"
      />
      <path
        d="M16.5 24h13.5"
        stroke="url(#hd-beam-grad)"
        strokeWidth="3.4"
        strokeLinecap="round"
      />
      <path
        d="M25.5 18.5 32 24l-6.5 5.5"
        fill="none"
        stroke="url(#hd-beam-grad)"
        strokeWidth="3.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function WordMark({ className }: { className?: string }) {
  return (
    <span className={cn("flex items-center gap-2.5", className)}>
      <HyperDropMark className="h-7 w-7 text-foreground" />
      <span className="font-display text-[1.05rem] font-semibold tracking-tight">HyperDrop</span>
    </span>
  );
}
