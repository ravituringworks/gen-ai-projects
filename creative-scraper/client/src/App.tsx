import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import Dashboard from "@/pages/dashboard";
import WebScraper from "@/pages/web-scraper";
import SocialMedia from "@/pages/social-media";
import AiAnalysis from "@/pages/ai-analysis";
import Visualizations from "@/pages/visualizations";
import Projects from "@/pages/projects";
import Exports from "@/pages/exports";
import Sidebar from "@/components/layout/sidebar";

function Router() {
  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Switch>
          <Route path="/" component={Dashboard} />
          <Route path="/web-scraper" component={WebScraper} />
          <Route path="/social-media" component={SocialMedia} />
          <Route path="/ai-analysis" component={AiAnalysis} />
          <Route path="/visualizations" component={Visualizations} />
          <Route path="/projects" component={Projects} />
          <Route path="/exports" component={Exports} />
          <Route component={NotFound} />
        </Switch>
      </div>
    </div>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Router />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
