"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Users, Zap, BookOpen, Flame, RefreshCw } from "lucide-react";
import { READING_LEVEL_LABELS, READING_LEVEL_BARS } from "@/lib/reading-levels";

interface AnalyticsData {
  totalStudents: number;
  activeToday: number;
  activeStudents: { id: string; name: string; lastActive: string | null; readingLevel: number }[];
  readingLevelDistribution: { level: number; count: number }[];
  streakLeaderboard: { id: string; name: string; streakDays: number; xp: number }[];
  xpLeaderboard: { id: string; name: string; xp: number; streakDays: number }[];
  recentActivity: {
    questId: string;
    buildingId: string;
    passed: boolean;
    studentName: string;
    completedAt: string | null;
  }[];
}

const PAGE_SIZE = 10;

function getMedalEmoji(rank: number): string | null {
  if (rank === 1) return "🥇";
  if (rank === 2) return "🥈";
  if (rank === 3) return "🥉";
  return null;
}

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
  const [xpPage, setXpPage] = useState(1);
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
          activeStudents: json.activeStudents ?? [],
          readingLevelDistribution: json.readingLevelDistribution ?? [],
          streakLeaderboard: json.streakLeaderboard ?? [],
          xpLeaderboard: json.xpLeaderboard ?? [],
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

  const avgLevelNum =
    data.readingLevelDistribution.length > 0
      ? data.readingLevelDistribution.reduce(
          (sum, d) => sum + d.level * d.count,
          0
        ) / data.totalStudents
      : null;
  const avgLevel =
    avgLevelNum !== null
      ? READING_LEVEL_LABELS[Math.round(avgLevelNum)] ?? "N/A"
      : "N/A";

  const streakTotalPages = Math.max(1, Math.ceil(data.streakLeaderboard.length / PAGE_SIZE));
  const safeStreakPage = Math.min(streakPage, streakTotalPages);
  const pagedStreak = data.streakLeaderboard.slice(
    (safeStreakPage - 1) * PAGE_SIZE,
    safeStreakPage * PAGE_SIZE
  );

  const xpTotalPages = Math.max(1, Math.ceil(data.xpLeaderboard.length / PAGE_SIZE));
  const safeXpPage = Math.min(xpPage, xpTotalPages);
  const pagedXp = data.xpLeaderboard.slice(
    (safeXpPage - 1) * PAGE_SIZE,
    safeXpPage * PAGE_SIZE
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
        <div>
          <h1 className="text-2xl font-bold">Dashboard Overview</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Welcome back — here&apos;s how your class is doing.</p>
        </div>
        <Button variant="outline" size="sm" onClick={handleRefresh} disabled={loading} className="gap-2">
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin" : ""}`} />
          {loading ? "Refreshing..." : "Refresh"}
        </Button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-l-4 border-l-blue-500">
          <CardHeader className="pb-2 flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Students</CardTitle>
            <div className="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center shrink-0">
              <Users className="w-4 h-4 text-blue-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{data.totalStudents}</div>
          </CardContent>
        </Card>
        <Card className="border-l-4 border-l-emerald-500">
          <CardHeader className="pb-2 flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active Today</CardTitle>
            <div className="w-8 h-8 rounded-lg bg-emerald-100 flex items-center justify-center shrink-0">
              <Zap className="w-4 h-4 text-emerald-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-emerald-600">{data.activeToday}</div>
          </CardContent>
        </Card>
        <Card className="border-l-4 border-l-violet-500">
          <CardHeader className="pb-2 flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-sm font-medium text-muted-foreground">Avg Reading Level</CardTitle>
            <div className="w-8 h-8 rounded-lg bg-violet-100 flex items-center justify-center shrink-0">
              <BookOpen className="w-4 h-4 text-violet-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{avgLevel}</div>
          </CardContent>
        </Card>
        <Card className="border-l-4 border-l-amber-500">
          <CardHeader className="pb-2 flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-sm font-medium text-muted-foreground">Top Streak</CardTitle>
            <div className="w-8 h-8 rounded-lg bg-amber-100 flex items-center justify-center shrink-0">
              <Flame className="w-4 h-4 text-amber-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-amber-600">
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
            {READING_LEVEL_BARS.map(({ level, label, color }) => {
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
                  <div className="flex-1 bg-muted rounded-full h-5 overflow-hidden">
                    <div
                      className={`${color} h-full rounded-full transition-all`}
                      style={{ width: pct === 0 ? "0%" : `${Math.max(pct, 3)}%` }}
                    />
                  </div>
                  <span className="text-sm font-medium w-8 text-right">{count}</span>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Active Students Today */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <span className="inline-block w-2 h-2 rounded-full bg-green-500 animate-pulse" />
            Active Students Today
            <span className="text-sm font-normal text-muted-foreground ml-1">
              ({data.activeStudents.length})
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {data.activeStudents.length === 0 ? (
            <p className="text-muted-foreground">No students active today yet.</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
              {data.activeStudents.map((s) => (
                <Link
                  key={s.id}
                  href={`/dashboard/students/${s.id}`}
                  className="flex items-center justify-between py-2 px-3 rounded border border-green-200 bg-green-50 hover:bg-green-100 transition-colors gap-2"
                >
                  <div className="flex items-center gap-2 min-w-0">
                    <span className="inline-block w-2 h-2 rounded-full bg-green-500 shrink-0" />
                    <span className="font-medium truncate text-sm">{s.name}</span>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <Badge variant="outline" className="text-xs">{READING_LEVEL_LABELS[s.readingLevel] ?? `L${s.readingLevel}`}</Badge>
                    {s.lastActive && (
                      <span className="text-xs text-muted-foreground">
                        {new Date(s.lastActive).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                      </span>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Leaderboards */}
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
                  {pagedStreak.map((s, i) => {
                    const rank = (safeStreakPage - 1) * PAGE_SIZE + i + 1;
                    const medal = getMedalEmoji(rank);
                    return (
                      <Link
                        key={s.id}
                        href={`/dashboard/students/${s.id}`}
                        className="flex items-center justify-between py-2 px-3 rounded hover:bg-muted transition-colors gap-2"
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <span className="text-sm w-6 shrink-0 text-center">
                            {medal ? medal : <span className="text-muted-foreground">#{rank}</span>}
                          </span>
                          <span className="font-medium truncate">{s.name}</span>
                        </div>
                        <Badge variant="secondary" className="bg-amber-100 text-amber-800 border-amber-200">
                          🔥 {s.streakDays}d
                        </Badge>
                      </Link>
                    );
                  })}
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

        {/* XP Leaderboard */}
        <Card>
          <CardHeader>
            <CardTitle>
              XP Leaderboard
              {xpTotalPages > 1 && (
                <span className="text-sm font-normal text-muted-foreground ml-2">
                  — page {safeXpPage} of {xpTotalPages}
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {data.xpLeaderboard.length === 0 ? (
              <p className="text-muted-foreground">No data yet.</p>
            ) : (
              <>
                <div className="space-y-2">
                  {pagedXp.map((s, i) => {
                    const rank = (safeXpPage - 1) * PAGE_SIZE + i + 1;
                    const medal = getMedalEmoji(rank);
                    return (
                      <Link
                        key={s.id}
                        href={`/dashboard/students/${s.id}`}
                        className="flex items-center justify-between py-2 px-3 rounded hover:bg-muted transition-colors gap-2"
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <span className="text-sm w-6 shrink-0 text-center">
                            {medal ? medal : <span className="text-muted-foreground">#{rank}</span>}
                          </span>
                          <span className="font-medium truncate">{s.name}</span>
                        </div>
                        <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                          ⭐ {s.xp} XP
                        </Badge>
                      </Link>
                    );
                  })}
                </div>
                <Pagination
                  page={safeXpPage}
                  totalPages={xpTotalPages}
                  onPageChange={setXpPage}
                />
              </>
            )}
          </CardContent>
        </Card>
      </div>

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
  );
}
