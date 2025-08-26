# LLM Patterns Frontend

A React-based frontend for testing and interacting with various LLM workflows and agents.

## Features

- Interactive UI for testing different LLM workflows
- Real-time chat interface for agent interactions
- Beautiful and modern design using Chakra UI
- Code editor for displaying structured responses
- Easy navigation between different patterns

## Getting Started

### Prerequisites

- Node.js 16+ installed
- Backend server running (see main project README)

### Installation

1. Install dependencies:

```bash
npm install
```

2. Start the development server:

```bash
npm run dev
```

The application will be available at `http://localhost:5173`.

### Running the Complete Stack

1. Start the backend server (from the project root):

```bash
cd backend
source venv/bin/activate
python main.py
```

2. Start the frontend development server (in a new terminal):

```bash
cd frontend
npm run dev
```

## Available Workflows

- Text Analysis
- Support Routing
- Content Moderation
- Document Processing
- Code Optimization

## Available Agents

- Research Assistant
- Medical Assistant

## Development

- Built with Vite + React + TypeScript
- Uses Chakra UI for components
- Monaco Editor for code display
- Axios for API requests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
