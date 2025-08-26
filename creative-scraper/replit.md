# Overview

DataCraft is a comprehensive web scraping and AI analysis platform that enables users to collect, analyze, and visualize data from various web sources. The application provides web scraping capabilities, social media data collection, AI-powered content analysis, data visualization, and export functionality. It's designed for professionals who need to gather and analyze web data for insights and decision-making.

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Frontend Architecture
- **React 18 with TypeScript**: Modern React application with full TypeScript support for type safety
- **Vite Build System**: Fast development server and optimized production builds
- **Wouter Router**: Lightweight client-side routing for single-page application navigation
- **TanStack Query**: Powerful data fetching, caching, and synchronization for API interactions
- **Shadcn/ui Components**: Comprehensive design system built on Radix UI primitives with Tailwind CSS styling
- **Tailwind CSS**: Utility-first CSS framework with custom design tokens and dark mode support

## Backend Architecture
- **Express.js Server**: RESTful API server with middleware for logging, error handling, and request processing
- **TypeScript**: Full type safety across the backend with shared schema definitions
- **Modular Route Structure**: Organized API endpoints for projects, scraping tasks, AI analysis, and exports
- **Memory Storage Pattern**: Abstracted storage interface allowing for easy database migration

## Data Layer
- **Drizzle ORM**: Type-safe SQL toolkit with PostgreSQL dialect configuration
- **PostgreSQL Database**: Primary data store with connection through Neon serverless
- **Shared Schema**: Common TypeScript definitions between frontend and backend for consistency
- **Migration Support**: Database schema versioning with Drizzle migrations

## Core Features Architecture

### Web Scraping Engine
- **Puppeteer Integration**: Headless browser automation for dynamic content extraction
- **Cheerio Parser**: Server-side jQuery-like HTML parsing for static content
- **Task Queue System**: Asynchronous scraping job management with status tracking
- **Content Extraction**: Structured data extraction including metadata, links, images, and text content

### AI Analysis Service
- **OpenAI Integration**: GPT-4o model for content analysis and insights generation
- **Multiple Analysis Types**: Sentiment analysis, trend detection, keyword extraction, and content summarization
- **Confidence Scoring**: Reliability metrics for AI-generated insights
- **Structured Output**: JSON-formatted analysis results for consistent processing

### Project Management
- **Multi-Project Support**: Isolated workspaces for different data collection initiatives
- **Task Tracking**: Real-time status monitoring for scraping and analysis operations
- **Data Organization**: Hierarchical structure linking projects to tasks, analyses, and exports

### Data Export System
- **Multiple Format Support**: Flexible export options (JSON, CSV, PDF planned)
- **Batch Processing**: Efficient handling of large dataset exports
- **Status Tracking**: Progress monitoring for long-running export operations

## Security & Configuration
- **Environment Variables**: Secure API key management for external services
- **CORS Configuration**: Proper cross-origin resource sharing setup
- **Session Management**: PostgreSQL-backed session storage with connect-pg-simple
- **Type-Safe Validation**: Zod schema validation for API requests and responses

## Development Environment
- **Hot Module Replacement**: Vite-powered development with instant updates
- **TypeScript Compilation**: Strict type checking with path mapping for clean imports
- **Error Handling**: Comprehensive error boundaries and logging for debugging
- **Replit Integration**: Custom plugins for development environment optimization

# External Dependencies

## Database Services
- **Neon PostgreSQL**: Serverless PostgreSQL database for data persistence
- **Drizzle ORM**: Database toolkit for schema management and queries

## AI/ML Services
- **OpenAI API**: GPT-4o model for natural language processing and content analysis

## Web Scraping
- **Puppeteer**: Headless Chrome automation for dynamic content scraping
- **Cheerio**: Server-side HTML parsing and manipulation

## Frontend Libraries
- **Radix UI**: Headless UI components for accessibility and functionality
- **Tailwind CSS**: Utility-first CSS framework for styling
- **TanStack Query**: Data fetching and state management
- **React Hook Form**: Form validation and management
- **Wouter**: Lightweight routing solution

## Development Tools
- **Vite**: Build tool and development server
- **TypeScript**: Static type checking
- **ESBuild**: Fast JavaScript bundler for production
- **Replit Plugins**: Development environment enhancements