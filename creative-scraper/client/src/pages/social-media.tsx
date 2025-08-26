import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import TopBar from "@/components/layout/topbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Hash, Search, AlertCircle } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function SocialMedia() {
  const [platform, setPlatform] = useState("");
  const [query, setQuery] = useState("");
  const [projectId, setProjectId] = useState("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const scrapeMutation = useMutation({
    mutationFn: async () => {
      if (!platform || !query || !projectId) {
        throw new Error("Platform, query, and project are required");
      }
      
      return apiRequest("POST", "/api/social-media/scrape", {
        platform,
        query,
        projectId: parseInt(projectId)
      });
    },
    onSuccess: () => {
      toast({
        title: "Social Media Scraping Started",
        description: "Your social media scraping task has been initiated.",
      });
      setQuery("");
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

  return (
    <>
      <TopBar 
        title="Social Media" 
        description="Extract data from social media platforms"
      />
      
      <main className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Platform Configuration */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Hash className="w-5 h-5" />
              <span>Social Media Scraping</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="platform">Platform</Label>
                <Select value={platform} onValueChange={setPlatform}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select platform..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="twitter">Twitter</SelectItem>
                    <SelectItem value="instagram">Instagram</SelectItem>
                    <SelectItem value="linkedin">LinkedIn</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="query">Search Query</Label>
                <Input
                  id="query"
                  placeholder="hashtag, keyword, or username"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="project">Project</Label>
                <Select value={projectId} onValueChange={setProjectId}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select project..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">Sample Project</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <Button
              onClick={() => scrapeMutation.mutate()}
              disabled={scrapeMutation.isPending || !platform || !query || !projectId}
              className="w-full"
            >
              {scrapeMutation.isPending ? (
                <>Scraping...</>
              ) : (
                <>
                  <Search className="w-4 h-4 mr-2" />
                  Start Social Media Scraping
                </>
              )}
            </Button>
          </CardContent>
        </Card>

        {/* API Configuration Notice */}
        <Card>
          <CardContent className="p-6">
            <div className="flex items-start space-x-3">
              <AlertCircle className="w-6 h-6 text-warning flex-shrink-0 mt-1" />
              <div>
                <h3 className="font-semibold text-gray-900 mb-2">API Configuration Required</h3>
                <p className="text-gray-600 mb-4">
                  Social media scraping requires API access from the respective platforms. 
                  Please configure your API credentials in the settings to enable this feature.
                </p>
                <div className="space-y-2 text-sm text-gray-500">
                  <p><strong>Twitter:</strong> Requires Twitter API v2 bearer token</p>
                  <p><strong>Instagram:</strong> Requires Instagram Basic Display API</p>
                  <p><strong>LinkedIn:</strong> Requires LinkedIn Marketing Developer Platform access</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Platform Guidelines */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Twitter</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Search by hashtags, keywords, or usernames</li>
                <li>• Rate limit: 300 requests per 15 minutes</li>
                <li>• Returns tweets, metrics, and user data</li>
                <li>• Supports real-time monitoring</li>
              </ul>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Instagram</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Extract posts, stories, and reels</li>
                <li>• Analyze engagement metrics</li>
                <li>• Hashtag performance tracking</li>
                <li>• Creator insights and analytics</li>
              </ul>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">LinkedIn</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Professional content analysis</li>
                <li>• Industry trend monitoring</li>
                <li>• Company page insights</li>
                <li>• B2B engagement metrics</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </main>
    </>
  );
}
