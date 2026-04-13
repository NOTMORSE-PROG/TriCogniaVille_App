"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

interface AnalyticsData {
  totalStudents: number;
  activeToday: number;
  readingLevelDistribution: { level: number; count: number }[];
  streakLeaderboard: { id: string; name: string; streakDays: number; xp: number }[];
  recentActivity: {
    questId: string;
    buildingId: string;
    passed: boolean;
    studentName: string;
    completedAt: string | null;
  }[];
}

const PAGE_SIZE = 10;

function Pagination({
  page,
  totalPages,
  onPageChange,
}: {
  page: number;
  totalPages: number;
  onPageChange: (p: number) => void;
}) {
  if (totalPages <= 1) return null;

  function getPageNumbers(): (number | "...")[] {
    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }
    const pages: (number | "...")[] = [1];
    if (page > 3) pages.push("...");
    for (let p = Math.max(2, page - 1); p <= Math.min(totalPages - 1, page + 1); p++) {
      pages.push(p);
    }
    if (page < totalPages - 2) pages.push("...");
    pages.push(totalPages);
    return pages;
  }

  return (
    <div className="flex items-center justify-center gap-1 pt-3">
      <Button
        variant="outline"
        size="sm"
        onClick={() => onPageChange(Math.max(1, page - 1))}
        disabled={page === 1}
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
            variant={page === p ? "default" : "outline"}
            size="sm"
            className="w-9"
            onClick={() => onPageChange(p)}
          >
            {p}
          </Button>
        )
      )}
      <Button
        variant="outline"
        size="sm"
        onClick={() => onPageChange(Math.min(totalPages, page + 1))}
        disabled={page === totalPages}
      >
        Next
      </Button>
    </div>
  );
}

export default function DashboardOverview() {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [streakPage, setStreakPage] = useState(1);
  const [activityPage, setActivityPage] = useState(1);

  const fetchData = useCallback(() => {
    fetch("/api/dashboard/analytics", { cache: "no-store" })
      .then((res) => {
        if (!res.ok) throw new Error(res.status === 401 ? "Not authenticated" : `API error ${res.status}`);
        return res.json();
      })
      .then((json) => {
        setData({
          ...json,
          readingLevelDistribution: json.readingLevelDistribution ?? [],
          streakLeaderboard: json.streakLeaderboard ?? [],
          recentActivity: json.recentActivity ?? [],
        });
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
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  if (loading) {
    return <div className="text-muted-foreground">Loading dashboard...</div>;
  }

  if (error) {
    return <div className="text-destructive">Error: {error}</div>;
  }

  if (!data) {
    return <div className="text-destructive">Failed to load dashboard data.</div>;
  }

  const avgLevel =
    data.readingLevelDistribution.length > 0
      ? (
          data.readingLevelDistribution.reduce(
            (sum, d) => sum + d.level * d.count,
            0
          ) / data.totalStudents
        ).toFixed(1)
      : "N/A";

  const streakTotalPages = Math.max(1, Math.ceil(data.streakLeaderboard.length / PAGE_SIZE));
  const safeStreakPage = Math.min(streakPage, streakTotalPages);
  const pagedStreak = data.streakLeaderboard.slice(
    (safeStreakPage - 1) * PAGE_SIZE,
    safeStreakPage * PAGE_SIZE
  );

  const activityTotalPages = Math.max(1, Math.ceil(data.recentActivity.length / PAGE_SIZE));
  const safeActivityPage = Math.min(activityPage, activityTotalPages);
  const pagedActivity = data.recentActivity.slice(
    (safeActivityPage - 1) * PAGE_SIZE,
    safeActivityPage * PAGE_SIZE
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Dashboard Overview</h1>
        <Button variant="outline" size="sm" onClick={handleRefresh} disabled={loading}>
          {loading ? "Refreshing..." : "Refresh"}
        </Button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Total Students</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{data.totalStudents}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Active Today</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{data.activeToday}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Avg Reading Level</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{avgLevel}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Top Streak</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {data.streakLeaderboard[0]?.streakDays || 0} days
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Reading Level Distribution */}
      <Card>
        <CardHeader>
          <CardTitle>Reading Level Distribution</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {[
              { level: 1, label: "Non Reader" },
              { level: 2, label: "Emerging" },
              { level: 3, label: "Developing" },
              { level: 4, label: "Fluent" },
            ].map(({ level, label }) => {
              const item = data.readingLevelDistribution.find(
                (d) => d.level === level
              );
              const count = item?.count ?? 0;
              const pct =
                data.totalStudents > 0
                  ? (count / data.totalStudents) * 100
                  : 0;
              return (
                <div key={level} className="flex items-center gap-3">
                  <span className="w-28 text-sm">
                    L{level}: {label}
                  </span>
                  <div className="flex-1 bg-muted rounded-full h-6 overflow-hidden">
                    <div
                      className="bg-primary h-full rounded-full transition-all"
                      style={{ width: pct === 0 ? "0%" : `${Math.max(pct, 3)}%` }}
                    />
                  </div>
                  <span className="text-sm font-medium w-8">{count}</span>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Streak Leaderboard */}
        <Card>
          <CardHeader>
            <CardTitle>
              Streak Leaderboard
              {streakTotalPages > 1 && (
                <span className="text-sm font-normal text-muted-foreground ml-2">
                  — page {safeStreakPage} of {streakTotalPages}
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {data.streakLeaderboard.length === 0 ? (
              <p className="text-muted-foreground">No data yet.</p>
            ) : (
              <>
                <div className="space-y-2">
                  {pagedStreak.map((s, i) => (
                    <Link
                      key={s.id}
                      href={`/dashboard/students/${s.id}`}
                      className="flex items-center justify-between py-2 px-3 rounded hover:bg-muted transition-colors gap-2"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <span className="text-muted-foreground text-sm w-6 shrink-0">
                          #{(safeStreakPage - 1) * PAGE_SIZE + i + 1}
                        </span>
                        <span className="font-medium truncate">{s.name}</span>
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        <Badge variant="secondary">{s.streakDays}d streak</Badge>
                        <Badge variant="outline">{s.xp} XP</Badge>
                      </div>
                    </Link>
                  ))}
                </div>
                <Pagination
                  page={safeStreakPage}
                  totalPages={streakTotalPages}
                  onPageChange={setStreakPage}
                />
              </>
            )}
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle>
              Recent Activity
              {activityTotalPages > 1 && (
                <span className="text-sm font-normal text-muted-foreground ml-2">
                  — page {safeActivityPage} of {activityTotalPages}
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {data.recentActivity.length === 0 ? (
              <p className="text-muted-foreground">No activity yet.</p>
            ) : (
              <>
                <div className="space-y-2">
                  {pagedActivity.map((a, i) => (
                    <div
                      key={`${safeActivityPage}-${i}`}
                      className="flex items-center justify-between py-2 px-3 rounded border gap-2"
                    >
                      <div className="min-w-0">
                        <span className="font-medium truncate block">{a.studentName}</span>
                        <span className="text-muted-foreground text-xs truncate block">
                          {a.buildingId} / {a.questId}
                        </span>
                      </div>
                      <Badge variant={a.passed ? "default" : "destructive"} className="shrink-0">
                        {a.passed ? "Passed" : "Failed"}
                      </Badge>
                    </div>
                  ))}
                </div>
                <Pagination
                  page={safeActivityPage}
                  totalPages={activityTotalPages}
                  onPageChange={setActivityPage}
                />
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
