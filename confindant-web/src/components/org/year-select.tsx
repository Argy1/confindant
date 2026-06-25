"use client";

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export function YearSelect({
  value,
  onChange,
  fromYear = 2023,
}: {
  value: number;
  onChange: (year: number) => void;
  fromYear?: number;
}) {
  const current = new Date().getFullYear();
  const years: number[] = [];
  for (let y = current; y >= fromYear; y--) years.push(y);

  return (
    <Select value={String(value)} onValueChange={(v) => onChange(Number(v))}>
      <SelectTrigger className="w-28">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {years.map((y) => (
          <SelectItem key={y} value={String(y)}>
            {y}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
