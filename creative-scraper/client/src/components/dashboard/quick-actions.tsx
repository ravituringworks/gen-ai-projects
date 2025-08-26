import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Globe, Settings, Sparkles, Play } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function QuickActions() {
  const [url, setUrl] = useState("");
  const [selectedDataSource, setSelectedDataSource] = useState("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const scrapeMutation = useMutation({
    mutationFn: async () => {
      if (!url) throw new Error("URL is required");
      
      // First create a quick project
      const projectResponse = await apiRequest("POST", "/api/projects", {
        name: `Quick Scrape - ${new URL(url).hostname}`,
        description: "Quick scraping task",
        status: "active",
        userId: 1
      });
      const project = await projectResponse.json();
      
      // Then start scraping
      return apiRequest("POST", "/api/scraping-tasks", {
        projectId: project.id,
        url,
        metadata: { type: "quick_scrape" }
      });
    },
    onSuccess: () => {
      toast({
        title: "Scraping Started",
        description: "Your scraping task has been initiated successfully.",
      });
      setUrl("");
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Scraping Failed",
        description: error.message,
        variant: "destructive",
      });
    }
  });

  const analysisMutation = useMutation({
    mutationFn: async () => {
      if (!selectedDataSource) throw new Error("Data source is required");
      
      // Create analysis based on selected source
      return apiRequest("POST", "/api/ai-analysis", {
        projectId: 1, // Default project for quick analysis
        type: "summary",
        sourceData: { type: selectedDataSource, timestamp: new Date() }
      });
    },
    onSuccess: () => {
      toast({
        title: "Analysis Started",
        description: "AI analysis is being generated for your data.",
      });
      setSelectedDataSource("");
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Analysis Failed",
        description: error.message,
        variant: "destructive",
      });
    }
  });

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Web Scraper Quick Start */}
      <Card className="shadow-sm">
        <CardContent className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Quick Scrape</h3>
            <Globe className="w-5 h-5 text-primary" />
          </div>
          <p className="text-gray-600 mb-4">Start scraping a website instantly</p>
          <div className="space-y-3">
            <Input
              type="url"
              placeholder="Enter website URL..."
              value={url}
              onChange={(e) => setUrl(e.target.value)}
            />
            <div className="flex space-x-2">
              <Button
                className="flex-1"
                onClick={() => scrapeMutation.mutate()}
                disabled={scrapeMutation.isPending || !url}
              >
                {scrapeMutation.isPending ? (
                  <>Loading...</>
                ) : (
                  <>
                    <Play className="w-4 h-4 mr-2" />
                    Start Scraping
                  </>
                )}
              </Button>
              <Button variant="outline" size="icon">
                <Settings className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* AI Analysis */}
      <Card className="shadow-sm">
        <CardContent className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">AI Analysis</h3>
            <Sparkles className="w-5 h-5 text-secondary" />
          </div>
          <p className="text-gray-600 mb-4">Generate insights from your data</p>
          <div className="space-y-3">
            <Select value={selectedDataSource} onValueChange={setSelectedDataSource}>
              <SelectTrigger>
                <SelectValue placeholder="Select data source..." />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="recent_scrapes">Recent web scrapes</SelectItem>
                <SelectItem value="social_media">Social media data</SelectItem>
                <SelectItem value="competitor">Competitor analysis</SelectItem>
              </SelectContent>
            </Select>
            <Button
              className="w-full bg-gradient-to-r from-secondary to-primary hover:opacity-90"
              onClick={() => analysisMutation.mutate()}
              disabled={analysisMutation.isPending || !selectedDataSource}
            >
              {analysisMutation.isPending ? (
                <>Generating...</>
              ) : (
                <>
                  <Sparkles className="w-4 h-4 mr-2" />
                  Generate Insights
                </>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
