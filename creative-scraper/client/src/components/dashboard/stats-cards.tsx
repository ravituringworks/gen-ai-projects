import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { TrendingUp, TrendingDown, Minus, Link, Brain, FolderOpen, Download } from "lucide-react";

export default function StatsCards() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["/api/stats"],
  });

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[...Array(4)].map((_, i) => (
          <Card key={i} className="animate-pulse">
            <CardContent className="p-6">
              <div className="h-20 bg-gray-200 rounded"></div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  const statCards = [
    {
      title: "URLs Scraped",
      value: stats?.urlsScraped || 0,
      trend: "+12% this week",
      trendIcon: TrendingUp,
      trendColor: "text-success",
      icon: Link,
      iconBg: "bg-blue-100",
      iconColor: "text-primary"
    },
    {
      title: "AI Insights",
      value: stats?.aiInsights || 0,
      trend: "+8% this week",
      trendIcon: TrendingUp,
      trendColor: "text-success",
      icon: Brain,
      iconBg: "bg-purple-100",
      iconColor: "text-secondary"
    },
    {
      title: "Active Projects",
      value: stats?.activeProjects || 0,
      trend: "-2% this week",
      trendIcon: TrendingDown,
      trendColor: "text-warning",
      icon: FolderOpen,
      iconBg: "bg-green-100",
      iconColor: "text-success"
    },
    {
      title: "Data Exported",
      value: stats?.dataExported || "0 GB",
      trend: "+24% this week",
      trendIcon: TrendingUp,
      trendColor: "text-success",
      icon: Download,
      iconBg: "bg-cyan-100",
      iconColor: "text-accent"
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {statCards.map((card, index) => {
        const TrendIcon = card.trendIcon;
        const Icon = card.icon;
        
        return (
          <Card key={index} className="shadow-sm">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{card.title}</p>
                  <p className="text-2xl font-bold text-gray-900">{card.value}</p>
                  <p className={`text-sm ${card.trendColor} flex items-center`}>
                    <TrendIcon className="w-3 h-3 mr-1" />
                    {card.trend}
                  </p>
                </div>
                <div className={`w-12 h-12 ${card.iconBg} rounded-lg flex items-center justify-center`}>
                  <Icon className={`w-6 h-6 ${card.iconColor}`} />
                </div>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}
