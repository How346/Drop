/**
 * HyperDrop prototype data layer.
 *
 * PROTOTYPE ONLY — this module models the shapes the production Flutter/Dart
 * app will own natively (discovery, pairing, chunked transfer). Nothing here
 * performs real networking, and no data leaves the browser.
 */

export type DeviceKind = "android-phone" | "android-tablet" | "windows-desktop" | "windows-laptop";

export interface Device {
  id: string;
  name: string;
  kind: DeviceKind;
  platform: "Android" | "Windows";
  lastConnected: string;
  trusted: boolean;
  blocked?: boolean;
}

export interface TransferFile {
  id: string;
  name: string;
  relativePath: string;
  mime: string;
  bytes: number;
  category: FileCategory;
}

export type FileCategory =
  | "photos"
  | "videos"
  | "documents"
  | "audio"
  | "archives"
  | "folders"
  | "other";

export interface HistoryEntry {
  id: string;
  fileName: string;
  deviceName: string;
  direction: "sent" | "received";
  bytes: number;
  at: string;
  status: "completed" | "failed" | "cancelled";
  note?: string;
}

export const thisDevice: Device = {
  id: "local",
  name: "Alex's Phone",
  kind: "android-phone",
  platform: "Android",
  lastConnected: "now",
  trusted: true,
};

export const pairedDevice: Device = {
  id: "dev-1",
  name: "Alex's Laptop",
  kind: "windows-laptop",
  platform: "Windows",
  lastConnected: "5 minutes ago",
  trusted: true,
};

export const recentDevices: Device[] = [
  pairedDevice,
  {
    id: "dev-2",
    name: "Sarah's Phone",
    kind: "android-phone",
    platform: "Android",
    lastConnected: "Yesterday",
    trusted: true,
  },
  {
    id: "dev-3",
    name: "Office PC",
    kind: "windows-desktop",
    platform: "Windows",
    lastConnected: "3 days ago",
    trusted: false,
  },
  {
    id: "dev-4",
    name: "Unknown Galaxy S25",
    kind: "android-phone",
    platform: "Android",
    lastConnected: "Last week",
    trusted: false,
    blocked: true,
  },
];

export const selectedFiles: TransferFile[] = [
  {
    id: "f1",
    name: "IMG_2048.jpg",
    relativePath: "Camera/IMG_2048.jpg",
    mime: "image/jpeg",
    bytes: 4_720_000,
    category: "photos",
  },
  {
    id: "f2",
    name: "Vacation.mp4",
    relativePath: "Movies/Vacation.mp4",
    mime: "video/mp4",
    bytes: 1_690_000_000,
    category: "videos",
  },
  {
    id: "f3",
    name: "Project.pdf",
    relativePath: "Documents/Project.pdf",
    mime: "application/pdf",
    bytes: 128_400_000,
    category: "documents",
  },
];

export const history: HistoryEntry[] = [
  {
    id: "h1",
    fileName: "Vacation.mp4",
    deviceName: "Alex's Laptop",
    direction: "sent",
    bytes: 1_290_000_000,
    at: "Today, 5:42 PM",
    status: "completed",
  },
  {
    id: "h2",
    fileName: "Design-System.sketch",
    deviceName: "Office PC",
    direction: "received",
    bytes: 214_000_000,
    at: "Today, 2:11 PM",
    status: "completed",
  },
  {
    id: "h3",
    fileName: "Backup-2026-08.zip",
    deviceName: "Sarah's Phone",
    direction: "sent",
    bytes: 8_400_000_000,
    at: "Yesterday, 9:02 PM",
    status: "failed",
    note: "Connection lost — resumable from 62%",
  },
  {
    id: "h4",
    fileName: "Invoice-1187.pdf",
    deviceName: "Alex's Laptop",
    direction: "received",
    bytes: 1_100_000,
    at: "Yesterday, 10:30 AM",
    status: "completed",
  },
  {
    id: "h5",
    fileName: "Podcast-ep-41.wav",
    deviceName: "Office PC",
    direction: "sent",
    bytes: 640_000_000,
    at: "Aug 22, 4:05 PM",
    status: "cancelled",
  },
];

export function formatBytes(bytes: number, digits = 2): string {
  if (bytes < 1000) return `${bytes} B`;
  const units = ["KB", "MB", "GB", "TB"];
  let value = bytes / 1000;
  let i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  return `${value.toFixed(value >= 100 ? 0 : digits)} ${units[i]}`;
}

export function formatSpeed(bytesPerSecond: number): string {
  return `${formatBytes(bytesPerSecond, 1)}/s`;
}

export function formatDuration(seconds: number): string {
  if (seconds < 60) return `${Math.round(seconds)} seconds`;
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  return `${m} min ${s.toString().padStart(2, "0")} s`;
}

export function formatCode(code: string): string {
  const clean = code.replace(/\D/g, "").slice(0, 6);
  return clean.length > 3 ? `${clean.slice(0, 3)} ${clean.slice(3)}` : clean;
}

export const totalSelectedBytes = selectedFiles.reduce((sum, f) => sum + f.bytes, 0);
