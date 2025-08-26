import { 
  users, projects, scrapingTasks, aiAnalyses, exports,
  type User, type InsertUser,
  type Project, type InsertProject,
  type ScrapingTask, type InsertScrapingTask,
  type AiAnalysis, type InsertAiAnalysis,
  type Export, type InsertExport
} from "@shared/schema";

export interface IStorage {
  // Users
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;

  // Projects
  getProjects(userId: number): Promise<Project[]>;
  getProject(id: number): Promise<Project | undefined>;
  createProject(project: InsertProject): Promise<Project>;
  updateProject(id: number, project: Partial<Project>): Promise<Project | undefined>;
  deleteProject(id: number): Promise<boolean>;

  // Scraping Tasks
  getScrapingTasks(projectId: number): Promise<ScrapingTask[]>;
  getScrapingTask(id: number): Promise<ScrapingTask | undefined>;
  createScrapingTask(task: InsertScrapingTask): Promise<ScrapingTask>;
  updateScrapingTask(id: number, task: Partial<ScrapingTask>): Promise<ScrapingTask | undefined>;

  // AI Analyses
  getAiAnalyses(projectId: number): Promise<AiAnalysis[]>;
  getAiAnalysis(id: number): Promise<AiAnalysis | undefined>;
  createAiAnalysis(analysis: InsertAiAnalysis): Promise<AiAnalysis>;

  // Exports
  getExports(projectId: number): Promise<Export[]>;
  createExport(exportData: InsertExport): Promise<Export>;
  updateExport(id: number, exportData: Partial<Export>): Promise<Export | undefined>;

  // Statistics
  getStats(userId: number): Promise<{
    urlsScraped: number;
    aiInsights: number;
    activeProjects: number;
    dataExported: string;
  }>;
}

export class MemStorage implements IStorage {
  private users: Map<number, User> = new Map();
  private projects: Map<number, Project> = new Map();
  private scrapingTasks: Map<number, ScrapingTask> = new Map();
  private aiAnalyses: Map<number, AiAnalysis> = new Map();
  private exports: Map<number, Export> = new Map();
  private currentUserId = 1;
  private currentProjectId = 1;
  private currentScrapingTaskId = 1;
  private currentAiAnalysisId = 1;
  private currentExportId = 1;

  constructor() {
    // Create default user
    this.createUser({
      username: "demo",
      password: "password",
      name: "Sarah Chen",
      role: "Creative Director"
    });
  }

  async getUser(id: number): Promise<User | undefined> {
    return this.users.get(id);
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(user => user.username === username);
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const id = this.currentUserId++;
    const user: User = {
      ...insertUser,
      id,
      createdAt: new Date(),
    };
    this.users.set(id, user);
    return user;
  }

  async getProjects(userId: number): Promise<Project[]> {
    return Array.from(this.projects.values()).filter(project => project.userId === userId);
  }

  async getProject(id: number): Promise<Project | undefined> {
    return this.projects.get(id);
  }

  async createProject(insertProject: InsertProject): Promise<Project> {
    const id = this.currentProjectId++;
    const now = new Date();
    const project: Project = {
      ...insertProject,
      id,
      createdAt: now,
      updatedAt: now,
    };
    this.projects.set(id, project);
    return project;
  }

  async updateProject(id: number, projectUpdate: Partial<Project>): Promise<Project | undefined> {
    const project = this.projects.get(id);
    if (!project) return undefined;
    
    const updatedProject: Project = {
      ...project,
      ...projectUpdate,
      updatedAt: new Date(),
    };
    this.projects.set(id, updatedProject);
    return updatedProject;
  }

  async deleteProject(id: number): Promise<boolean> {
    return this.projects.delete(id);
  }

  async getScrapingTasks(projectId: number): Promise<ScrapingTask[]> {
    return Array.from(this.scrapingTasks.values()).filter(task => task.projectId === projectId);
  }

  async getScrapingTask(id: number): Promise<ScrapingTask | undefined> {
    return this.scrapingTasks.get(id);
  }

  async createScrapingTask(insertTask: InsertScrapingTask): Promise<ScrapingTask> {
    const id = this.currentScrapingTaskId++;
    const task: ScrapingTask = {
      ...insertTask,
      id,
      status: "pending",
      data: null,
      errorMessage: null,
      startedAt: null,
      completedAt: null,
      createdAt: new Date(),
    };
    this.scrapingTasks.set(id, task);
    return task;
  }

  async updateScrapingTask(id: number, taskUpdate: Partial<ScrapingTask>): Promise<ScrapingTask | undefined> {
    const task = this.scrapingTasks.get(id);
    if (!task) return undefined;
    
    const updatedTask: ScrapingTask = { ...task, ...taskUpdate };
    this.scrapingTasks.set(id, updatedTask);
    return updatedTask;
  }

  async getAiAnalyses(projectId: number): Promise<AiAnalysis[]> {
    return Array.from(this.aiAnalyses.values()).filter(analysis => analysis.projectId === projectId);
  }

  async getAiAnalysis(id: number): Promise<AiAnalysis | undefined> {
    return this.aiAnalyses.get(id);
  }

  async createAiAnalysis(insertAnalysis: InsertAiAnalysis): Promise<AiAnalysis> {
    const id = this.currentAiAnalysisId++;
    const analysis: AiAnalysis = {
      ...insertAnalysis,
      id,
      analysis: {},
      insights: null,
      confidence: null,
      createdAt: new Date(),
    };
    this.aiAnalyses.set(id, analysis);
    return analysis;
  }

  async getExports(projectId: number): Promise<Export[]> {
    return Array.from(this.exports.values()).filter(exp => exp.projectId === projectId);
  }

  async createExport(insertExport: InsertExport): Promise<Export> {
    const id = this.currentExportId++;
    const exportData: Export = {
      ...insertExport,
      id,
      status: "pending",
      fileName: null,
      filePath: null,
      createdAt: new Date(),
    };
    this.exports.set(id, exportData);
    return exportData;
  }

  async updateExport(id: number, exportUpdate: Partial<Export>): Promise<Export | undefined> {
    const exportData = this.exports.get(id);
    if (!exportData) return undefined;
    
    const updatedExport: Export = { ...exportData, ...exportUpdate };
    this.exports.set(id, updatedExport);
    return updatedExport;
  }

  async getStats(userId: number): Promise<{
    urlsScraped: number;
    aiInsights: number;
    activeProjects: number;
    dataExported: string;
  }> {
    const userProjects = await this.getProjects(userId);
    const projectIds = userProjects.map(p => p.id);
    
    const urlsScraped = Array.from(this.scrapingTasks.values())
      .filter(task => projectIds.includes(task.projectId) && task.status === "completed").length;
    
    const aiInsights = Array.from(this.aiAnalyses.values())
      .filter(analysis => projectIds.includes(analysis.projectId)).length;
    
    const activeProjects = userProjects.filter(p => p.status === "active").length;
    
    return {
      urlsScraped,
      aiInsights,
      activeProjects,
      dataExported: "156 GB"
    };
  }
}

export const storage = new MemStorage();
