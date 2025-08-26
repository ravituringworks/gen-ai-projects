import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import TopBar from "@/components/layout/topbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Globe, Play, Settings, Clock, CheckCircle, XCircle } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function WebScraper() {
  const [url, setUrl] = useState("");
  const [selectedProject, setSelectedProject] = useState("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: projects } = useQuery({
    queryKey: ["/api/projects"],
  });

  const { data: scrapingTasks, isLoading: tasksLoading } = useQuery({
    queryKey: ["/api/projects", selectedProject, "scraping-tasks"],
    enabled: !!selectedProject,
  });

  const scrapeMutation = useMutation({
    mutationFn: async () => {
      if (!url || !selectedProject) throw new Error("URL and project are required");
      
      return apiRequest("POST", "/api/scraping-tasks", {
        projectId: parseInt(selectedProject),
        url,
        metadata: { type: "manual_scrape" }
      });
    },
    onSuccess: () => {
      toast({
        title: "Scraping Started",
        description: "Your scraping task has been initiated successfully.",
      });
      setUrl("");
      queryClient.invalidateQueries({ queryKey: ["/api/projects", selectedProject, "scraping-tasks"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Scraping Failed",
        description: error.message,
        variant: "destructive",
      });
    }
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "completed":
        return <CheckCircle className="w-4 h-4 text-success" />;
      case "failed":
        return <XCircle className="w-4 h-4 text-error" />;
      case "running":
        return <Clock className="w-4 h-4 text-warning animate-spin" />;
      default:
        return <Clock className="w-4 h-4 text-gray-400" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-success";
      case "failed":
        return "bg-error";
      case "running":
        return "bg-warning";
      default:
        return "bg-gray-400";
    }
  };

  return (
    <>
      <TopBar 
        title="Web Scraper" 
        description="Extract content and data from websites"
      />
      
      <main className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Scraping Form */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Globe className="w-5 h-5" />
              <span>Start New Scraping Task</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="url">Website URL</Label>
                <Input
                  id="url"
                  type="url"
                  placeholder="https://example.com"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="project">Project</Label>
                <Select value={selectedProject} onValueChange={setSelectedProject}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a project..." />
                  </SelectTrigger>
                  <SelectContent>
                    {projects?.map((project) => (
                      <SelectItem key={project.id} value={project.id.toString()}>
                        {project.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <div className="flex space-x-2">
              <Button
                onClick={() => scrapeMutation.mutate()}
                disabled={scrapeMutation.isPending || !url || !selectedProject}
                className="flex-1"
              >
                {scrapeMutation.isPending ? (
                  <>Starting...</>
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
          </CardContent>
        </Card>

        {/* Scraping Tasks */}
        {selectedProject && (
          <Card>
            <CardHeader>
              <CardTitle>Scraping Tasks</CardTitle>
            </CardHeader>
            <CardContent>
              {tasksLoading ? (
                <div className="space-y-4">
                  {[...Array(3)].map((_, i) => (
                    <div key={i} className="h-16 bg-gray-200 rounded animate-pulse"></div>
                  ))}
                </div>
              ) : scrapingTasks?.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  No scraping tasks yet. Start your first scrape above!
                </p>
              ) : (
                <div className="space-y-4">
                  {scrapingTasks?.map((task) => (
                    <div
                      key={task.id}
                      className="flex items-center justify-between p-4 border border-gray-200 rounded-lg"
                    >
                      <div className="flex items-center space-x-4">
                        {getStatusIcon(task.status)}
                        <div>
                          <p className="font-medium text-gray-900">{task.url}</p>
                          <p className="text-sm text-gray-600">
                            {task.data?.title || "No title extracted"}
                          </p>
                          <p className="text-xs text-gray-400">
                            Created {new Date(task.createdAt).toLocaleString()}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Badge className={getStatusColor(task.status)}>
                          {task.status.charAt(0).toUpperCase() + task.status.slice(1)}
                        </Badge>
                        {task.data?.metadata?.wordCount && (
                          <Badge variant="outline">
                            {task.data.metadata.wordCount} words
                          </Badge>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </main>
    </>
  );
}
