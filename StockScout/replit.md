# Multi-Agent Stock Research Platform

## Overview

This is a sophisticated multi-agent research platform designed to autonomously analyze and select the top 100 high-growth stocks from NASDAQ and OTC markets. The system uses Agent-to-Agent (A2A) communication protocols and Model Context Protocol (MCP) technologies to coordinate specialized AI agents that handle data acquisition, analysis, and forecasting across multiple time horizons (1 day, 1 week, 1 month). The platform operates fully autonomously, performing daily market scans and generating explainable stock recommendations with detailed research rationales.

## User Preferences

Preferred communication style: Simple, everyday language.

## Recent Changes

### August 3, 2025
- Resolved all database prepared statement conflicts using raw SQL queries with persistent(false)
- Backend now successfully serves authentic stock data including NFLX, BABA, NVDA with real scores
- Replaced server connection error popups with seamless automatic retry functionality
- Implemented comprehensive resilience patterns: retry logic, circuit breakers, caching with TTL
- Removed blocking initialization screen - app now shows content immediately
- Added visual stock charts and performance indicators for top stocks
- Enhanced UI with retry status widgets and graceful loading states
- All critical API endpoints operational: /api/agents/health, /api/agents/status, /api/stocks/top/1day
- System confirmed working with 100 authentic stocks and real market analysis data

## System Architecture

### Multi-Agent Architecture
The system is built around a distributed agent framework where specialized AI agents communicate via A2A protocols:

- **Data Acquisition Agents**: Responsible for fetching comprehensive market data including stock prices, news, SEC filings, sentiment data, and fundamental metrics for all NASDAQ and OTC securities
- **Analysis Agents**: Perform specialized analysis including technical indicators, fundamental screening, sentiment analysis, and volume pattern detection
- **Time-Horizon Forecasting Agents**: Three dedicated agents optimized for short-term (1 day), medium-term (1 week), and long-term (1 month) predictions
- **Master Coordinating Agent**: Orchestrates workflow, manages inter-agent communication, resolves conflicts, and synthesizes final rankings

### Technology Stack
The platform leverages a multi-language architecture:

- **Frontend**: Flutter web application for user interface
- **Backend Services**: Rust-based high-performance computing components for real-time data processing
- **Database**: PostgreSQL with Supabase for managed database services
- **Cross-Platform Logic**: Dart for shared business logic between web and mobile platforms

### MCP Integration Layer
Model Context Protocol implementation provides:

- **Standardized Tool Access**: Unified interface for accessing market data APIs, news feeds, and broker platforms
- **Context Sharing**: Distributed working memory allowing all agents to access prior results, market state, and historical decisions
- **Dynamic Service Discovery**: Automatic detection and integration of new data sources without custom coding

### Data Processing Pipeline
The system operates on a continuous cycle:

1. **Market Scanning**: Comprehensive data ingestion of all active NASDAQ and OTC securities
2. **Parallel Analysis**: Multiple specialized agents run concurrent analysis pipelines
3. **Cross-Agent Collaboration**: Agents share intermediate findings and debate candidate selections via A2A protocols
4. **Result Synthesis**: Master agent aggregates inputs, applies meta-ranking algorithms, and generates justified top 100 lists
5. **Output Generation**: Produces three ranked lists (one per time horizon) with detailed research explanations

### Scalability and Performance Design
- **Parallel Processing**: Agents operate concurrently to handle the vast universe of stocks efficiently
- **Modular Architecture**: Easy addition or replacement of agents due to standardized A2A and MCP interfaces
- **Real-time Updates**: Daily execution cycle with continuous market data ingestion

## External Dependencies

### Market Data Sources
- Real-time and historical stock price feeds for NASDAQ and OTC markets
- Financial news aggregation services
- SEC filing databases and APIs
- Social sentiment analysis platforms
- Options flow and unusual activity data providers

### Database and Infrastructure
- **PostgreSQL**: Primary data storage for historical market data, agent states, and analysis results (database operational with 926 stocks and 741 authentic analysis results)
- **Connection Monitoring**: Frontend includes server health checks and connection alerts for port 8000 verification

### Development and Runtime
- **Flutter SDK**: Cross-platform UI framework
- **Dart SDK**: Application logic and agent communication protocols
- **Rust Toolchain**: High-performance backend services and real-time data processing
- **Web APIs**: Browser-based deployment for the Flutter web application

### AI/ML Services
- Machine learning model hosting for predictive analytics
- Natural language processing services for news and sentiment analysis
- Time series analysis libraries for technical indicators

### Compliance and Monitoring
- Audit logging systems for all agent communications and decisions
- Market data compliance tracking
- Performance monitoring and alerting systems