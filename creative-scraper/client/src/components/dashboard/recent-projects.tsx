import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Hash, Globe, BarChart3, MoreHorizontal } from "lucide-react";
import { Link } from "wouter";

export default function RecentProjects() {
  const { data: projects, isLoading } = useQuery({
    queryKey: ["/api/projects"],
  });

  if (isLoading) {
    return (
      <Card className="shadow-sm">
        <CardContent className="p-6">
          <div className="animate-pulse">
            <div className="h-6 bg-gray-200 rounded mb-6"></div>
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="h-16 bg-gray-200 rounded"></div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  const recentProjects = projects?.slice(0, 3) || [];

  const getProjectIcon = (index: number) => {
    const icons = [Hash, Globe, BarChart3];
    const Icon = icons[index % icons.length];
    return Icon;
  };

  const getProjectGradient = (index: number) => {
    const gradients = [
      "from-primary to-secondary",
      "from-accent to-success",
      "from-secondary to-accent"
    ];
    return gradients[index % gradients.length];
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "bg-success text-white";
      case "processing":
        return "bg-warning text-white";
      case "completed":
        return "bg-gray-400 text-white";
      default:
        return "bg-gray-300 text-gray-700";
    }
  };

  return (
    <Card className="shadow-sm">
      <CardContent className="p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">Recent Projects</h3>
          <Link href="/projects">
            <Button variant="ghost" className="text-primary hover:text-blue-700">
              View All
            </Button>
          </Link>
        </div>
        
        <div className="space-y-4">
          {recentProjects.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <p>No projects yet. Create your first project to get started!</p>
            </div>
          ) : (
            recentProjects.map((project, index) => {
              const Icon = getProjectIcon(index);
              const gradient = getProjectGradient(index);
              
              return (
                <div
                  key={project.id}
                  className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <div className="flex items-center space-x-4">
                    <div className={`w-10 h-10 bg-gradient-to-br ${gradient} rounded-lg flex items-center justify-center`}>
                      <Icon className="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <h4 className="font-medium text-gray-900">{project.name}</h4>
                      <p className="text-sm text-gray-600">{project.description}</p>
                      <p className="text-xs text-gray-400">
                        Updated {new Date(project.updatedAt).toLocaleString()}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(project.status)}`}>
                      {project.status.charAt(0).toUpperCase() + project.status.slice(1)}
                    </span>
                    <button className="text-gray-400 hover:text-gray-600">
                      <MoreHorizontal className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </CardContent>
    </Card>
  );
}
