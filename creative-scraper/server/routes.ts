import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { webScraper } from "./services/scraper";
import { aiAnalysisService } from "./services/openai";
import { insertProjectSchema, insertScrapingTaskSchema, insertAiAnalysisSchema, insertExportSchema } from "@shared/schema";

export async function registerRoutes(app: Express): Promise<Server> {
  // Projects
  app.get("/api/projects", async (req, res) => {
    try {
      const userId = 1; // In a real app, get from session/auth
      const projects = await storage.getProjects(userId);
      res.json(projects);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  app.post("/api/projects", async (req, res) => {
    try {
      const userId = 1; // In a real app, get from session/auth
      const projectData = insertProjectSchema.parse({ ...req.body, userId });
      const project = await storage.createProject(projectData);
      res.json(project);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  app.put("/api/projects/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const project = await storage.updateProject(id, req.body);
      if (!project) {
        return res.status(404).json({ error: "Project not found" });
      }
      res.json(project);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  app.delete("/api/projects/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const deleted = await storage.deleteProject(id);
      if (!deleted) {
        return res.status(404).json({ error: "Project not found" });
      }
      res.json({ success: true });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Scraping Tasks
  app.get("/api/projects/:projectId/scraping-tasks", async (req, res) => {
    try {
      const projectId = parseInt(req.params.projectId);
      const tasks = await storage.getScrapingTasks(projectId);
      res.json(tasks);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  app.post("/api/scraping-tasks", async (req, res) => {
    try {
      const taskData = insertScrapingTaskSchema.parse(req.body);
      const task = await storage.createScrapingTask(taskData);
      
      // Start scraping in background
      setImmediate(async () => {
        try {
          await storage.updateScrapingTask(task.id, { 
            status: "running", 
            startedAt: new Date() 
          });
          
          const result = await webScraper.scrapeUrl(task.url);
          
          await storage.updateScrapingTask(task.id, {
            status: "completed",
            data: result,
            completedAt: new Date()
          });
        } catch (error) {
          await storage.updateScrapingTask(task.id, {
            status: "failed",
            errorMessage: error.message,
            completedAt: new Date()
          });
        }
      });
      
      res.json(task);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // AI Analysis
  app.get("/api/projects/:projectId/ai-analyses", async (req, res) => {
    try {
      const projectId = parseInt(req.params.projectId);
      const analyses = await storage.getAiAnalyses(projectId);
      res.json(analyses);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  app.post("/api/ai-analysis", async (req, res) => {
    try {
      const { projectId, type, sourceData } = req.body;
      const analysisData = insertAiAnalysisSchema.parse({ projectId, type, sourceData });
      
      let analysis = await storage.createAiAnalysis(analysisData);
      
      // Perform AI analysis based on type
      try {
        let result: any;
        let insights: string;
        let confidence: number;

        switch (type) {
          case 'sentiment':
            const sentimentResult = await aiAnalysisService.analyzeSentiment(JSON.stringify(sourceData));
            result = sentimentResult;
            insights = sentimentResult.summary;
            confidence = Math.round(sentimentResult.confidence * 100);
            break;
            
          case 'trends':
            const trendResult = await aiAnalysisService.analyzeTrends(Array.isArray(sourceData) ? sourceData : [sourceData]);
            result = trendResult;
            insights = `Identified ${trendResult.keywords.length} trending keywords and ${trendResult.topics.length} key topics`;
            confidence = 85;
            break;
            
          case 'summary':
            const contentResult = await aiAnalysisService.generateContentInsights(JSON.stringify(sourceData));
            result = contentResult;
            insights = contentResult.summary;
            confidence = 90;
            break;
            
          default:
            throw new Error(`Unsupported analysis type: ${type}`);
        }

        analysis = await storage.updateAiAnalysis(analysis.id, {
          analysis: result,
          insights,
          confidence
        });
      } catch (error) {
        analysis = await storage.updateAiAnalysis(analysis.id, {
          analysis: { error: error.message },
          insights: `Analysis failed: ${error.message}`,
          confidence: 0
        });
      }
      
      res.json(analysis);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Statistics
  app.get("/api/stats", async (req, res) => {
    try {
      const userId = 1; // In a real app, get from session/auth
      const stats = await storage.getStats(userId);
      res.json(stats);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Social Media Scraping
  app.post("/api/social-media/scrape", async (req, res) => {
    try {
      const { platform, query, projectId } = req.body;
      
      const results = await webScraper.scrapeSocialMedia(platform, query);
      
      // Store results as scraping tasks
      const tasks = await Promise.all(
        results.map(result => 
          storage.createScrapingTask({
            projectId,
            url: `${platform}:${query}`,
            metadata: { platform, query, type: 'social_media' }
          }).then(task => 
            storage.updateScrapingTask(task.id, {
              status: "completed",
              data: result,
              completedAt: new Date()
            })
          )
        )
      );
      
      res.json(tasks);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Exports
  app.post("/api/exports", async (req, res) => {
    try {
      const exportData = insertExportSchema.parse(req.body);
      const exportRecord = await storage.createExport(exportData);
      
      // Process export in background
      setImmediate(async () => {
        try {
          const { projectId, format } = exportData;
          const scrapingTasks = await storage.getScrapingTasks(projectId);
          const aiAnalyses = await storage.getAiAnalyses(projectId);
          
          const fileName = `export_${projectId}_${Date.now()}.${format}`;
          let fileContent: string;
          
          switch (format) {
            case 'json':
              fileContent = JSON.stringify({ scrapingTasks, aiAnalyses }, null, 2);
              break;
            case 'csv':
              // Simple CSV conversion (in a real app, use a proper CSV library)
              const csvData = scrapingTasks.map(task => ({
                url: task.url,
                status: task.status,
                createdAt: task.createdAt,
                title: task.data?.title || '',
                wordCount: task.data?.metadata?.wordCount || 0
              }));
              fileContent = 'URL,Status,Created,Title,Word Count\n' + 
                csvData.map(row => Object.values(row).join(',')).join('\n');
              break;
            default:
              throw new Error(`Unsupported format: ${format}`);
          }
          
          await storage.updateExport(exportRecord.id, {
            status: "completed",
            fileName,
            filePath: `/exports/${fileName}`
          });
        } catch (error) {
          await storage.updateExport(exportRecord.id, {
            status: "failed"
          });
        }
      });
      
      res.json(exportRecord);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}
