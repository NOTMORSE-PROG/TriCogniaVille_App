"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

interface Student {
  id: string;
  name: string;
  email: string;
  username: string | null;
  readingLevel: number;
  xp: number;
  streakDays: number;
  lastActive: string | null;
  onboardingDone: boolean;
  createdAt: string;
}

const LEVEL_LABELS: Record<number, string> = {
  1: "Non Reader",
  2: "Emerging",
  3: "Developing",
  4: "Fluent",
};

function levelVariant(level: number): "default" | "secondary" | "outline" | "destructive" {
  if (level === 4) return "default";
  if (level === 3) return "secondary";
  if (level === 2) return "outline";
  return "destructive";
}

function formatLastActive(dateStr: string | null): string {
  if (!dateStr) return "Never";
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString();
}

const PAGE_SIZE = 10;

export default function StudentsPage() {
  const [students, setStudents] = useState<Student[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  const fetchStudents = useCallback(() => {
    fetch("/api/dashboard/students", { cache: "no-store" })
      .then((res) => {
        if (!res.ok) throw new Error(res.status === 401 ? "Not authenticated" : `API error ${res.status}`);
        return res.json();
      })
      .then((json) => {
        setStudents(json.students ?? []);
        setError(null);
        setLoading(false);
      })
      .catch((err) => {
        setError((err as Error).message);
        setLoading(false);
      });
  }, []);

  const handleRefresh = useCallback(() => {
    setLoading(true);
    setError(null);
    fetchStudents();
  }, [fetchStudents]);

  useEffect(() => {
    fetchStudents();
  }, [fetchStudents]);

  const filtered = students.filter((s) => {
    const q = search.toLowerCase();
    return (
      s.name.toLowerCase().includes(q) ||
      s.email.toLowerCase().includes(q) ||
      (s.username ?? "").toLowerCase().includes(q)
    );
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const pageStudents = filtered.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  function getPageNumbers(): (number | "...")[] {
    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }
    const pages: (number | "...")[] = [1];
    if (safePage > 3) pages.push("...");
    for (let p = Math.max(2, safePage - 1); p <= Math.min(totalPages - 1, safePage + 1); p++) {
      pages.push(p);
    }
    if (safePage < totalPages - 2) pages.push("...");
    pages.push(totalPages);
    return pages;
  }

  if (loading) {
    return <div className="text-muted-foreground">Loading students...</div>;
  }

  if (error) {
    return <div className="text-destructive">Error: {error}</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">All Students</h1>
          <p className="text-muted-foreground text-sm mt-1">
            {students.length} student{students.length !== 1 ? "s" : ""} registered
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={handleRefresh} disabled={loading}>
          {loading ? "Refreshing..." : "Refresh"}
        </Button>
      </div>

      <Input
        placeholder="Search by name, email, or username..."
        value={search}
        onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        className="max-w-sm"
      />

      {filtered.length === 0 ? (
        <Card>
          <CardContent className="py-10 text-center text-muted-foreground">
            {search ? "No students match your search." : "No students registered yet."}
          </CardContent>
        </Card>
      ) : (
        <>
          <Card>
            <CardHeader>
              <CardTitle>
                Students ({filtered.length})
                {totalPages > 1 && (
                  <span className="text-sm font-normal text-muted-foreground ml-2">
                    — page {safePage} of {totalPages}
                  </span>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y">
                {pageStudents.map((student) => (
                  <Link
                    key={student.id}
                    href={`/dashboard/students/${student.id}`}
                    className="flex items-center justify-between px-6 py-4 hover:bg-muted/50 transition-colors gap-4"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-medium truncate">{student.name}</span>
                        {!student.onboardingDone && (
                          <Badge variant="outline" className="text-xs shrink-0">
                            Setup pending
                          </Badge>
                        )}
                      </div>
                      <div className="text-sm text-muted-foreground truncate">
                        {student.email}
                        {student.username ? ` · @${student.username}` : ""}
                      </div>
                    </div>

                    <div className="flex items-center gap-3 shrink-0">
                      <Badge variant={levelVariant(student.readingLevel)}>
                        L{student.readingLevel} {LEVEL_LABELS[student.readingLevel]}
                      </Badge>
                      <div className="hidden sm:flex items-center gap-2">
                        <Badge variant="secondary">{student.xp} XP</Badge>
                        {student.streakDays > 0 && (
                          <Badge variant="outline">{student.streakDays}d streak</Badge>
                        )}
                      </div>
                      <span className="text-xs text-muted-foreground hidden md:block w-20 text-right">
                        {formatLastActive(student.lastActive)}
                      </span>
                    </div>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>

          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-1">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={safePage === 1}
              >
                Prev
              </Button>

              {getPageNumbers().map((p, i) =>
                p === "..." ? (
                  <span key={`ellipsis-${i}`} className="px-2 text-muted-foreground select-none">
                    …
                  </span>
                ) : (
                  <Button
                    key={p}
                    variant={safePage === p ? "default" : "outline"}
                    size="sm"
                    className="w-9"
                    onClick={() => setPage(p)}
                  >
                    {p}
                  </Button>
                )
              )}

              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={safePage === totalPages}
              >
                Next
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
