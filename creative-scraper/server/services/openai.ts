import OpenAI from "openai";

// the newest OpenAI model is "gpt-4o" which was released May 13, 2024. do not change this unless explicitly requested by the user
const openai = new OpenAI({ 
  apiKey: process.env.OPENAI_API_KEY || process.env.OPENAI_API_KEY_ENV_VAR || "default_key" 
});

export interface SentimentAnalysis {
  rating: number; // 1-5 stars
  confidence: number; // 0-1
  summary: string;
}

export interface TrendAnalysis {
  keywords: string[];
  topics: string[];
  sentiment: 'positive' | 'negative' | 'neutral';
  insights: string[];
}

export interface ContentInsights {
  summary: string;
  keyPoints: string[];
  recommendations: string[];
  competitorAnalysis?: string;
}

export class AIAnalysisService {
  async analyzeSentiment(text: string): Promise<SentimentAnalysis> {
    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a sentiment analysis expert for creative professionals. Analyze the sentiment of the provided content and provide a rating from 1 to 5 stars, a confidence score between 0 and 1, and a brief summary. Respond with JSON in this format: { 'rating': number, 'confidence': number, 'summary': string }"
          },
          {
            role: "user",
            content: `Analyze the sentiment of this content:\n\n${text}`
          }
        ],
        response_format: { type: "json_object" },
      });

      const result = JSON.parse(response.choices[0].message.content || '{}');
      
      return {
        rating: Math.max(1, Math.min(5, Math.round(result.rating))),
        confidence: Math.max(0, Math.min(1, result.confidence)),
        summary: result.summary || "Sentiment analysis completed"
      };
    } catch (error: any) {
      throw new Error("Failed to analyze sentiment: " + error.message);
    }
  }

  async analyzeTrends(data: any[]): Promise<TrendAnalysis> {
    try {
      const combinedText = data.map(item => 
        typeof item === 'string' ? item : JSON.stringify(item)
      ).join('\n\n');

      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a trend analysis expert for creative professionals. Analyze the provided data to identify trending keywords, topics, overall sentiment, and actionable insights. Respond with JSON in this format: { 'keywords': string[], 'topics': string[], 'sentiment': string, 'insights': string[] }"
          },
          {
            role: "user",
            content: `Analyze trends in this data:\n\n${combinedText}`
          }
        ],
        response_format: { type: "json_object" },
      });

      const result = JSON.parse(response.choices[0].message.content || '{}');
      
      return {
        keywords: result.keywords || [],
        topics: result.topics || [],
        sentiment: result.sentiment || 'neutral',
        insights: result.insights || []
      };
    } catch (error: any) {
      throw new Error("Failed to analyze trends: " + error.message);
    }
  }

  async generateContentInsights(content: string, context?: string): Promise<ContentInsights> {
    try {
      const prompt = context 
        ? `Analyze this content in the context of ${context}:\n\n${content}`
        : `Analyze this content for creative professionals:\n\n${content}`;

      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a content analysis expert for creative professionals. Provide a comprehensive analysis including summary, key points, and actionable recommendations. Respond with JSON in this format: { 'summary': string, 'keyPoints': string[], 'recommendations': string[], 'competitorAnalysis': string }"
          },
          {
            role: "user",
            content: prompt
          }
        ],
        response_format: { type: "json_object" },
      });

      const result = JSON.parse(response.choices[0].message.content || '{}');
      
      return {
        summary: result.summary || "Content analysis completed",
        keyPoints: result.keyPoints || [],
        recommendations: result.recommendations || [],
        competitorAnalysis: result.competitorAnalysis
      };
    } catch (error: any) {
      throw new Error("Failed to generate content insights: " + error.message);
    }
  }

  async generateCreativeRecommendations(data: any, goals: string[]): Promise<string[]> {
    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a creative strategy advisor. Based on the provided data and goals, generate specific, actionable recommendations for creative professionals. Respond with JSON in this format: { 'recommendations': string[] }"
          },
          {
            role: "user",
            content: `Data: ${JSON.stringify(data)}\n\nGoals: ${goals.join(', ')}\n\nGenerate creative recommendations based on this information.`
          }
        ],
        response_format: { type: "json_object" },
      });

      const result = JSON.parse(response.choices[0].message.content || '{}');
      return result.recommendations || [];
    } catch (error: any) {
      throw new Error("Failed to generate recommendations: " + error.message);
    }
  }
}

export const aiAnalysisService = new AIAnalysisService();
