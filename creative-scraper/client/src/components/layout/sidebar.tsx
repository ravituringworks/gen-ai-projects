import { Link, useLocation } from "wouter";
import { Database, BarChart3, Globe, Hash, Brain, FolderOpen, Download, Settings } from "lucide-react";
import { cn } from "@/lib/utils";

const navigationItems = [
  { path: "/", label: "Dashboard", icon: BarChart3 },
  { path: "/web-scraper", label: "Web Scraper", icon: Globe },
  { path: "/social-media", label: "Social Media", icon: Hash },
  { path: "/ai-analysis", label: "AI Analysis", icon: Brain },
  { path: "/visualizations", label: "Visualizations", icon: BarChart3 },
  { path: "/projects", label: "Projects", icon: FolderOpen },
  { path: "/exports", label: "Exports", icon: Download },
];

export default function Sidebar() {
  const [location] = useLocation();

  return (
    <div className="w-64 bg-white shadow-lg border-r border-gray-200 flex flex-col">
      {/* Logo Header */}
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center">
            <Database className="w-4 h-4 text-white" />
          </div>
          <span className="text-xl font-bold text-gray-900">DataCraft</span>
        </div>
      </div>

      {/* Navigation Menu */}
      <nav className="flex-1 px-4 py-6 space-y-2">
        {navigationItems.map((item) => {
          const Icon = item.icon;
          const isActive = location === item.path || (item.path !== "/" && location.startsWith(item.path));
          
          return (
            <Link key={item.path} href={item.path}>
              <div className={cn(
                "flex items-center space-x-3 px-3 py-2 rounded-lg transition-colors cursor-pointer",
                isActive 
                  ? "bg-primary text-white" 
                  : "text-gray-700 hover:bg-gray-100"
              )}>
                <Icon className="w-5 h-5" />
                <span>{item.label}</span>
              </div>
            </Link>
          );
        })}
      </nav>

      {/* User Profile */}
      <div className="p-4 border-t border-gray-200">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
            <span className="text-sm font-medium text-gray-600">SC</span>
          </div>
          <div className="flex-1">
            <p className="text-sm font-medium text-gray-900">Sarah Chen</p>
            <p className="text-xs text-gray-500">Creative Director</p>
          </div>
          <button className="text-gray-400 hover:text-gray-600">
            <Settings className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
