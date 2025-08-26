import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { BarChart3 } from "lucide-react";

export default function DataOverview() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["/api/stats"],
  });

  if (isLoading) {
    return (
      <Card className="shadow-sm">
        <CardContent className="p-6">
          <div className="animate-pulse">
            <div className="h-6 bg-gray-200 rounded mb-6"></div>
            <div className="h-64 bg-gray-200 rounded mb-6"></div>
            <div className="grid grid-cols-3 gap-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="h-16 bg-gray-200 rounded"></div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="shadow-sm">
      <CardContent className="p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Data Overview</h3>
            <p className="text-gray-600">Visual summary of your collected data</p>
          </div>
          <div className="flex space-x-2">
            <Button variant="outline" size="sm">Week</Button>
            <Button size="sm">Month</Button>
            <Button variant="outline" size="sm">Year</Button>
          </div>
        </div>

        {/* Chart Placeholder */}
        <div className="h-64 bg-gradient-to-br from-gray-50 to-gray-100 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300 mb-6">
          <div className="text-center">
            <BarChart3 className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600 font-medium">Interactive Data Visualization</p>
            <p className="text-sm text-gray-500 mt-1">Chart.js or D3.js integration for real-time data display</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="text-center">
            <p className="text-2xl font-bold text-primary">{stats?.urlsScraped || 0}</p>
            <p className="text-sm text-gray-600">Total Scrapes</p>
          </div>
          <div className="text-center">
            <p className="text-2xl font-bold text-secondary">{stats?.aiInsights || 0}</p>
            <p className="text-sm text-gray-600">AI Analyses</p>
          </div>
          <div className="text-center">
            <p className="text-2xl font-bold text-success">94.2%</p>
            <p className="text-sm text-gray-600">Success Rate</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
