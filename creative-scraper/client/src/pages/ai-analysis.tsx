import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import TopBar from "@/components/layout/topbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Brain, Sparkles, TrendingUp, MessageSquare, FileText } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function AiAnalysis() {
  const [selectedProject, setSelectedProject] = useState("");
  const [analysisType, setAnalysisType] = useState("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: projects } = useQuery({
    queryKey: ["/api/projects"],
  });

  const { data: analyses, isLoading: analysesLoading } = useQuery({
    queryKey: ["/api/projects", selectedProject, "ai-analyses"],
    enabled: !!selectedProject,
  });

  const { data: scrapingTasks } = useQuery({
    queryKey: ["/api/projects", selectedProject, "scraping-tasks"],
    enabled: !!selectedProject,
  });

  const analysisMutation = useMutation({
    mutationFn: async () => {
      if (!selectedProject || !analysisType) {
        throw new Error("Project and analysis type are required");
      }
      
      // Get available data for analysis
      const completedTasks = scrapingTasks?.filter(task => task.status === "completed") || [];
      if (completedTasks.length === 0) {
        throw new Error("No completed scraping tasks found for analysis");
      }
      
      const sourceData = completedTasks.map(task => task.data);
      
      return apiRequest("POST", "/api/ai-analysis", {
        projectId: parseInt(selectedProject),
        type: analysisType,
        sourceData
      });
    },
    onSuccess: () => {
      toast({
        title: "AI Analysis Started",
        description: "Your AI analysis is being generated.",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/projects", selectedProject, "ai-analyses"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Analysis Failed",
        description: error.message,
        variant: "destructive",
      });
    }
  });

  const getAnalysisIcon = (type: string) => {
    switch (type) {
      case "sentiment":
        return MessageSquare;
      case "trends":
        return TrendingUp;
      case "summary":
        return FileText;
      default:
        return Brain;
    }
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 80) return "bg-success";
    if (confidence >= 60) return "bg-warning";
    return "bg-gray-400";
  };

  return (
    <>
      <TopBar 
        title="AI Analysis" 
        description="Generate insights from your scraped data using AI"
      />
      
      <main className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Analysis Configuration */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Brain className="w-5 h-5" />
              <span>Generate AI Analysis</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
              
              <div className="space-y-2">
                <Label htmlFor="analysisType">Analysis Type</Label>
                <Select value={analysisType} onValueChange={setAnalysisType}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select analysis type..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sentiment">Sentiment Analysis</SelectItem>
                    <SelectItem value="trends">Trend Analysis</SelectItem>
                    <SelectItem value="summary">Content Summary</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <Button
              onClick={() => analysisMutation.mutate()}
              disabled={analysisMutation.isPending || !selectedProject || !analysisType}
              className="w-full bg-gradient-to-r from-secondary to-primary hover:opacity-90"
            >
              {analysisMutation.isPending ? (
                <>Analyzing...</>
              ) : (
                <>
                  <Sparkles className="w-4 h-4 mr-2" />
                  Generate Analysis
                </>
              )}
            </Button>
          </CardContent>
        </Card>

        {/* Analysis Results */}
        {selectedProject && (
          <Card>
            <CardHeader>
              <CardTitle>Analysis Results</CardTitle>
            </CardHeader>
            <CardContent>
              {analysesLoading ? (
                <div className="space-y-4">
                  {[...Array(3)].map((_, i) => (
                    <div key={i} className="h-24 bg-gray-200 rounded animate-pulse"></div>
                  ))}
                </div>
              ) : analyses?.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  No analyses yet. Generate your first AI analysis above!
                </p>
              ) : (
                <div className="space-y-4">
                  {analyses?.map((analysis) => {
                    const Icon = getAnalysisIcon(analysis.type);
                    
                    return (
                      <div
                        key={analysis.id}
                        className="p-4 border border-gray-200 rounded-lg"
                      >
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex items-center space-x-3">
                            <Icon className="w-5 h-5 text-primary" />
                            <div>
                              <h3 className="font-medium text-gray-900">
                                {analysis.type.charAt(0).toUpperCase() + analysis.type.slice(1)} Analysis
                              </h3>
                              <p className="text-sm text-gray-500">
                                {new Date(analysis.createdAt).toLocaleString()}
                              </p>
                            </div>
                          </div>
                          {analysis.confidence && (
                            <Badge className={getConfidenceColor(analysis.confidence)}>
                              {analysis.confidence}% confidence
                            </Badge>
                          )}
                        </div>
                        
                        {analysis.insights && (
                          <div className="mb-3">
                            <h4 className="font-medium text-gray-900 mb-1">Insights</h4>
                            <p className="text-gray-600">{analysis.insights}</p>
                          </div>
                        )}
                        
                        {analysis.analysis && typeof analysis.analysis === 'object' && (
                          <div className="bg-gray-50 rounded-lg p-3">
                            <h4 className="font-medium text-gray-900 mb-2">Detailed Analysis</h4>
                            <pre className="text-sm text-gray-600 whitespace-pre-wrap">
                              {JSON.stringify(analysis.analysis, null, 2)}
                            </pre>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {/* Analysis Types Info */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center space-x-2">
                <MessageSquare className="w-5 h-5" />
                <span>Sentiment Analysis</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Analyze emotional tone of content</li>
                <li>• Rate sentiment from 1-5 stars</li>
                <li>• Confidence scoring</li>
                <li>• Summary of overall sentiment</li>
              </ul>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center space-x-2">
                <TrendingUp className="w-5 h-5" />
                <span>Trend Analysis</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Identify trending keywords</li>
                <li>• Extract key topics</li>
                <li>• Overall sentiment trends</li>
                <li>• Actionable insights</li>
              </ul>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center space-x-2">
                <FileText className="w-5 h-5" />
                <span>Content Summary</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Comprehensive content analysis</li>
                <li>• Key points extraction</li>
                <li>• Creative recommendations</li>
                <li>• Competitor insights</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </main>
    </>
  );
}
