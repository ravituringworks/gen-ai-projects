import TopBar from "@/components/layout/topbar";
import StatsCards from "@/components/dashboard/stats-cards";
import QuickActions from "@/components/dashboard/quick-actions";
import RecentProjects from "@/components/dashboard/recent-projects";
import AiInsights from "@/components/dashboard/ai-insights";
import DataOverview from "@/components/dashboard/data-overview";

export default function Dashboard() {
  const handleNewProject = () => {
    // This would open a modal or redirect to create project page
    console.log("Creating new project...");
  };

  return (
    <>
      <TopBar 
        title="Dashboard" 
        description="Monitor your data collection and AI insights"
        onNewProject={handleNewProject}
      />
      
      <main className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Stats Cards */}
        <StatsCards />

        {/* Quick Actions */}
        <QuickActions />

        {/* Recent Activity & Projects */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Recent Projects */}
          <div className="lg:col-span-2">
            <RecentProjects />
          </div>

          {/* AI Insights Panel */}
          <AiInsights />
        </div>

        {/* Data Visualization Preview */}
        <DataOverview />
      </main>
    </>
  );
}
