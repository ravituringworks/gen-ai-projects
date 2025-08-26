import { pgTable, text, serial, integer, boolean, timestamp, jsonb } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  name: text("name").notNull(),
  role: text("role").notNull().default("user"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const projects = pgTable("projects", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  status: text("status").notNull().default("active"), // active, processing, completed, paused
  userId: integer("user_id").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const scrapingTasks = pgTable("scraping_tasks", {
  id: serial("id").primaryKey(),
  projectId: integer("project_id").notNull(),
  url: text("url").notNull(),
  status: text("status").notNull().default("pending"), // pending, running, completed, failed
  data: jsonb("data"), // scraped content
  metadata: jsonb("metadata"), // scraping configuration and results
  errorMessage: text("error_message"),
  startedAt: timestamp("started_at"),
  completedAt: timestamp("completed_at"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const aiAnalyses = pgTable("ai_analyses", {
  id: serial("id").primaryKey(),
  projectId: integer("project_id").notNull(),
  type: text("type").notNull(), // sentiment, trends, keywords, summary
  sourceData: jsonb("source_data").notNull(),
  analysis: jsonb("analysis").notNull(),
  insights: text("insights"),
  confidence: integer("confidence"), // 0-100
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const exports = pgTable("exports", {
  id: serial("id").primaryKey(),
  projectId: integer("project_id").notNull(),
  format: text("format").notNull(), // csv, json, pdf
  status: text("status").notNull().default("pending"), // pending, processing, completed, failed
  fileName: text("file_name"),
  filePath: text("file_path"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// Insert schemas
export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
  name: true,
  role: true,
});

export const insertProjectSchema = createInsertSchema(projects).pick({
  name: true,
  description: true,
  status: true,
  userId: true,
});

export const insertScrapingTaskSchema = createInsertSchema(scrapingTasks).pick({
  projectId: true,
  url: true,
  metadata: true,
});

export const insertAiAnalysisSchema = createInsertSchema(aiAnalyses).pick({
  projectId: true,
  type: true,
  sourceData: true,
});

export const insertExportSchema = createInsertSchema(exports).pick({
  projectId: true,
  format: true,
});

// Types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;

export type Project = typeof projects.$inferSelect;
export type InsertProject = z.infer<typeof insertProjectSchema>;

export type ScrapingTask = typeof scrapingTasks.$inferSelect;
export type InsertScrapingTask = z.infer<typeof insertScrapingTaskSchema>;

export type AiAnalysis = typeof aiAnalyses.$inferSelect;
export type InsertAiAnalysis = z.infer<typeof insertAiAnalysisSchema>;

export type Export = typeof exports.$inferSelect;
export type InsertExport = z.infer<typeof insertExportSchema>;
