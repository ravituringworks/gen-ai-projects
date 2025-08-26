import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import TopBar from "@/components/layout/topbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Download, FileText, FileJson, Clock, CheckCircle, XCircle } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Exports() {
  const [selectedProject, setSelectedProject] = useState("");
  const [exportFormat, setExportFormat] = useState("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: projects } = useQuery({
    queryKey: ["/api/projects"],
  });

  const { data: exports, isLoading: exportsLoading } = useQuery({
    queryKey: ["/api/projects", selectedProject, "exports"],
    enabled: !!selectedProject,
  });

  const exportMutation = useMutation({
    mutationFn: async () => {
      if (!selectedProject || !exportFormat) {
        throw new Error("Project and format are required");
      }
      
      return apiRequest("POST", "/api/exports", {
        projectId: parseInt(selectedProject),
        format: exportFormat
      });
    },
    onSuccess: () => {
      toast({
        title: "Export Started",
        description: "Your data export has been initiated.",
      });
      setExportFormat("");
      queryClient.invalidateQueries({ queryKey: ["/api/projects", selectedProject, "exports"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Export Failed",
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
      case "processing":
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
      case "processing":
        return "bg-warning";
      default:
        return "bg-gray-400";
    }
  };

  const getFormatIcon = (format: string) => {
    switch (format) {
      case "json":
        return <FileJson className="w-4 h-4" />;
      case "csv":
        return <FileText className="w-4 h-4" />;
      default:
        return <FileText className="w-4 h-4" />;
    }
  };

  return (
    <>
      <TopBar 
        title="Exports" 
        description="Export your collected data in various formats"
      />
      
      <main className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Export Configuration */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Download className="w-5 h-5" />
              <span>Create New Export</span>
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
                <Label htmlFor="format">Export Format</Label>
                <Select value={exportFormat} onValueChange={setExportFormat}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select format..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="json">JSON</SelectItem>
                    <SelectItem value="csv">CSV</SelectItem>
                    <SelectItem value="pdf">PDF Report</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <Button
              onClick={() => exportMutation.mutate()}
              disabled={exportMutation.isPending || !selectedProject || !exportFormat}
              className="w-full"
            >
              {exportMutation.isPending ? (
                <>Processing...</>
              ) : (
                <>
                  <Download className="w-4 h-4 mr-2" />
                  Start Export
                </>
              )}
            </Button>
          </CardContent>
        </Card>

        {/* Export History */}
        {selectedProject && (
          <Card>
            <CardHeader>
              <CardTitle>Export History</CardTitle>
            </CardHeader>
            <CardContent>
              {exportsLoading ? (
                <div className="space-y-4">
                  {[...Array(3)].map((_, i) => (
                    <div key={i} className="h-16 bg-gray-200 rounded animate-pulse"></div>
                  ))}
                </div>
              ) : exports?.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  No exports yet. Create your first export above!
                </p>
              ) : (
                <div className="space-y-4">
                  {exports?.map((exportItem) => (
                    <div
                      key={exportItem.id}
                      className="flex items-center justify-between p-4 border border-gray-200 rounded-lg"
                    >
                      <div className="flex items-center space-x-4">
                        {getStatusIcon(exportItem.status)}
                        {getFormatIcon(exportItem.format)}
                        <div>
                          <p className="font-medium text-gray-900">
                            {exportItem.fileName || `Export ${exportItem.id}`}
                          </p>
                          <p className="text-sm text-gray-600">
                            {exportItem.format.toUpperCase()} format
                          </p>
                          <p className="text-xs text-gray-400">
                            Created {new Date(exportItem.createdAt).toLocaleString()}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Badge className={getStatusColor(exportItem.status)}>
                          {exportItem.status.charAt(0).toUpperCase() + exportItem.status.slice(1)}
                        </Badge>
                        {exportItem.status === "completed" && (
                          <Button variant="outline" size="sm">
                            <Download className="w-4 h-4 mr-2" />
                            Download
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {/* Export Format Information */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center space-x-2">
                <FileJson className="w-5 h-5" />
                <span>JSON Export</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Complete data structure</li>
                <li>• Includes metadata and analysis</li>
                <li>• Machine-readable format</li>
                <li>• Perfect for API integration</li>
              </ul>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center space-x-2">
                <FileText className="w-5 h-5" />
                <span>CSV Export</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Spreadsheet-friendly format</li>
                <li>• Basic data structure</li>
                <li>• Easy to import in Excel</li>
                <li>• Ideal for data analysis</li>
              </ul>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center space-x-2">
                <FileText className="w-5 h-5" />
                <span>PDF Report</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-600 space-y-2">
                <li>• Formatted report with charts</li>
                <li>• Executive summary</li>
                <li>• Key insights and trends</li>
                <li>• Ready for presentations</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </main>
    </>
  );
}
