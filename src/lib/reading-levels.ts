export const READING_LEVEL_LABELS: Record<number, string> = {
  1: "Non Reader",
  2: "Emerging",
  3: "Developing",
  4: "Fluent",
};

export const READING_LEVEL_BARS: ReadonlyArray<{
  level: number;
  label: string;
  color: string;
}> = [
  { level: 1, label: "Non Reader", color: "bg-rose-400" },
  { level: 2, label: "Emerging",   color: "bg-amber-400" },
  { level: 3, label: "Developing", color: "bg-blue-500" },
  { level: 4, label: "Fluent",     color: "bg-emerald-500" },
];
