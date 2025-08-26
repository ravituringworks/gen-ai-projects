import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Lightbulb, TrendingUp, Users } from "lucide-react";
import { Link } from "wouter";

export default function AiInsights() {
  const { data: analyses, isLoading } = useQuery({
    queryKey: ["/api/projects/1/ai-analyses"], // Using project 1 for demo
  });

  if (isLoading) {
    return (
      <Card className="shadow-sm">
        <CardContent className="p-6">
          <div className="animate-pulse">
            <div className="h-6 bg-gray-200 rounded mb-6"></div>
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="h-20 bg-gray-200 rounded"></div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  const recentInsights = analyses?.slice(0, 3) || [];

  const getInsightIcon = (type: string) => {
    switch (type) {
      case 'trends':
        return TrendingUp;
      case 'sentiment':
        return Users;
      default:
        return Lightbulb;
    }
  };

  const getInsightColor = (index: number) => {
    const colors = [
      { bg: "from-blue-50 to-purple-50", border: "border-primary", icon: "text-primary" },
      { bg: "from-green-50 to-cyan-50", border: "border-success", icon: "text-success" },
      { bg: "from-purple-50 to-pink-50", border: "border-secondary", icon: "text-secondary" }
    ];
    return colors[index % colors.length];
  };

  const defaultInsights = [
    {
      type: "trends",
      insights: '"Sustainable fashion" mentions increased 45% this week across monitored sources.',
      createdAt: new Date(Date.now() - 2 * 60000), // 2 minutes ago
      confidence: 85
    },
    {
      type: "sentiment",
      insights: "Best posting time: 2-4 PM on weekdays based on scraped data.",
      createdAt: new Date(Date.now() - 15 * 60000), // 15 minutes ago
      confidence: 90
    },
    {
      type: "summary",
      insights: "Your target demographic shows 23% higher engagement with video content.",
      createdAt: new Date(Date.now() - 60 * 60000), // 1 hour ago
      confidence: 78
    }
  ];

  const displayInsights = recentInsights.length > 0 ? recentInsights : defaultInsights;

  const getTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - new Date(date).getTime()) / (1000 * 60));
    
    if (diffInMinutes < 1) return "Just now";
    if (diffInMinutes < 60) return `${diffInMinutes} minutes ago`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)} hours ago`;
    return `${Math.floor(diffInMinutes / 1440)} days ago`;
  };

  return (
    <Card className="shadow-sm">
      <CardContent className="p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">Latest Insights</h3>
          <div className="w-2 h-2 bg-success rounded-full animate-pulse"></div>
        </div>
        
        <div className="space-y-4">
          {displayInsights.map((insight, index) => {
            const Icon = getInsightIcon(insight.type);
            const colors = getInsightColor(index);
            
            return (
              <div
                key={index}
                className={`p-4 bg-gradient-to-r ${colors.bg} rounded-lg border-l-4 ${colors.border}`}
              >
                <div className="flex items-start space-x-3">
                  <Icon className={`w-5 h-5 ${colors.icon} mt-1 flex-shrink-0`} />
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900 mb-1">
                      {insight.type === 'trends' ? 'Trending Keywords' : 
                       insight.type === 'sentiment' ? 'Engagement Pattern' : 
                       'Audience Insight'}
                    </h4>
                    <p className="text-sm text-gray-600">{insight.insights}</p>
                    <p className="text-xs text-gray-400 mt-2">
                      {getTimeAgo(insight.createdAt)}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <Link href="/ai-analysis">
          <Button 
            variant="ghost" 
            className="w-full mt-4 text-primary hover:text-blue-700 border-t border-gray-200 rounded-none"
          >
            View All Insights
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}
