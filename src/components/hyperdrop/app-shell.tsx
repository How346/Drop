import type { ReactNode } from "react";
import { Link, useRouterState } from "@tanstack/react-router";
import {
  Home,
  Radio,
  ArrowLeftRight,
  History,
  MonitorSmartphone,
  Settings,
  BookOpen,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { WordMark } from "./logo";
import { LiveDot } from "./primitives";
import { thisDevice } from "@/lib/hyperdrop";

interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
}

const nav: NavItem[] = [
  { to: "/", label: "Home", icon: Home },
  { to: "/connect", label: "Connect", icon: Radio },
  { to: "/transfer", label: "Transfer", icon: ArrowLeftRight },
  { to: "/history", label: "History", icon: History },
  { to: "/devices", label: "Devices", icon: MonitorSmartphone },
  { to: "/settings", label: "Settings", icon: Settings },
  { to: "/spec", label: "Spec", icon: BookOpen },
];

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = useRouterState({ select: (s) => s.location.pathname });

  return (
    <div className="min-h-screen bg-background">
      {/* Windows-style navigation rail (desktop) */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-60 flex-col border-r border-sidebar-border bg-sidebar px-3 py-5 lg:flex">
        <Link to="/" className="mb-7 px-2.5">
          <WordMark />
        </Link>
        <nav className="flex flex-1 flex-col gap-0.5" aria-label="Main">
          {nav.map((item) => (
            <RailLink key={item.to} item={item} active={isActive(pathname, item.to)} />
          ))}
        </nav>
        <div className="rounded-xl border border-sidebar-border bg-sidebar-accent px-3 py-3">
          <div className="flex items-center gap-2 text-xs font-medium">
            <LiveDot />
            Discoverable
          </div>
          <p className="mt-1.5 truncate text-xs text-muted-foreground">{thisDevice.name}</p>
          <p className="text-xs text-muted-foreground">Local Wi-Fi · Home-5G</p>
        </div>
      </aside>

      {/* Mobile top bar */}
      <header className="sticky top-0 z-30 flex items-center justify-between border-b border-border bg-background/85 px-4 py-3 backdrop-blur lg:hidden">
        <Link to="/">
          <WordMark />
        </Link>
        <span className="inline-flex items-center gap-2 text-xs text-muted-foreground">
          <LiveDot />
          Discoverable
        </span>
      </header>

      <main className="pb-24 lg:pb-0 lg:pl-60">
        <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 lg:px-10 lg:py-10">
          {children}
        </div>
      </main>

      {/* Android-style bottom navigation */}
      <nav
        className="fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 border-t border-border bg-background/95 pb-[env(safe-area-inset-bottom)] backdrop-blur lg:hidden"
        aria-label="Main"
      >
        {nav.slice(0, 5).map((item) => {
          const active = isActive(pathname, item.to);
          return (
            <Link
              key={item.to}
              to={item.to}
              className={cn(
                "flex min-h-12 flex-col items-center justify-center gap-1 py-2 text-[0.68rem] font-medium transition-colors",
                active ? "text-primary" : "text-muted-foreground",
              )}
            >
              <item.icon className="size-5" aria-hidden />
              {item.label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}

function isActive(pathname: string, to: string) {
  return to === "/" ? pathname === "/" : pathname.startsWith(to);
}

function RailLink({ item, active }: { item: NavItem; active: boolean }) {
  return (
    <Link
      to={item.to}
      className={cn(
        "group flex items-center gap-3 rounded-lg px-2.5 py-2 text-sm font-medium transition-colors",
        active
          ? "bg-sidebar-accent text-sidebar-accent-foreground"
          : "text-muted-foreground hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground",
      )}
    >
      <span
        className={cn(
          "h-5 w-0.5 rounded-full transition-colors",
          active ? "bg-primary" : "bg-transparent",
        )}
        aria-hidden
      />
      <item.icon className="size-4" aria-hidden />
      {item.label}
    </Link>
  );
}
