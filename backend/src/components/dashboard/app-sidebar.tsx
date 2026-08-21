"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { LayoutDashboard, Users, BarChart3, LogOut, Building2 } from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarGroupContent,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarHeader,
  SidebarFooter,
} from "@/components/ui/sidebar";
import { Button } from "@/components/ui/button";

const navItems = [
  { title: "Overview", href: "/dashboard", icon: LayoutDashboard },
  { title: "Students", href: "/dashboard/students", icon: Users },
  { title: "Analytics", href: "/dashboard/analytics", icon: BarChart3 },
];

export function AppSidebar() {
  const pathname = usePathname();

  async function handleLogout() {
    await fetch("/api/auth/teacher/logout", { method: "POST" });
    window.location.href = "/sign-in";
  }

  return (
    <Sidebar>
      <SidebarHeader className="p-4 pb-3">
        <Link href="/dashboard" className="flex items-center gap-3">
          <div className="flex items-center justify-center w-9 h-9 rounded-xl bg-sidebar-primary/20 shrink-0">
            <Building2 className="w-5 h-5 text-sidebar-primary" />
          </div>
          <div className="min-w-0">
            <span className="font-bold text-base text-sidebar-foreground leading-tight block">
              TriCognia Ville
            </span>
            <span className="text-xs text-sidebar-foreground/50 leading-tight block">
              Teacher Dashboard
            </span>
          </div>
        </Link>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel className="text-sidebar-foreground/40 uppercase text-[10px] tracking-widest font-semibold px-3">
            Navigation
          </SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive =
                  item.href === "/dashboard"
                    ? pathname === "/dashboard"
                    : pathname.startsWith(item.href);
                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton
                      isActive={isActive}
                      render={<Link href={item.href} />}
                      className="gap-3 font-medium"
                    >
                      <Icon className="w-4 h-4 shrink-0" />
                      {item.title}
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className="p-3">
        <Button
          variant="ghost"
          className="w-full justify-start gap-3 text-sidebar-foreground/70 hover:text-sidebar-foreground hover:bg-sidebar-accent font-medium"
          onClick={handleLogout}
        >
          <LogOut className="w-4 h-4 shrink-0" />
          Sign Out
        </Button>
      </SidebarFooter>
    </Sidebar>
  );
}
