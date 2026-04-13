import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/dashboard/app-sidebar";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <main className="flex-1 overflow-auto bg-background">
        <div className="flex items-center gap-3 border-b border-b-primary/20 bg-secondary/30 px-4 py-2.5 shadow-sm">
          <SidebarTrigger className="text-muted-foreground hover:text-foreground" />
          <div className="h-4 w-px bg-border" />
          <span className="text-sm text-foreground font-semibold tracking-wide">TriCognia Ville</span>
        </div>
        <div className="p-4 sm:p-6">{children}</div>
      </main>
    </SidebarProvider>
  );
}
