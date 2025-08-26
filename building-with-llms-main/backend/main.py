from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any
import json

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class WorkflowInput(BaseModel):
    input: str

class AgentInput(BaseModel):
    message: str

# Mock workflow responses
WORKFLOW_RESPONSES = {
    "text-analysis": lambda x: {"analysis": f"Analyzed text: {x}", "sentiment": "positive"},
    "support-routing": lambda x: {"department": "technical", "priority": "high", "reason": "Technical issue detected"},
    "content-moderation": lambda x: {"is_appropriate": True, "confidence": 0.95, "categories": ["safe", "general"]},
    "document-processing": lambda x: {"sections": ["intro", "main", "conclusion"], "summary": "Document processed successfully"},
    "code-optimization": lambda x: {"optimized_code": "def optimized(): pass", "improvements": ["reduced complexity", "better naming"]},
}

# Mock agent responses
AGENT_RESPONSES = {
    "research-assistant": lambda x: f"Research assistant response to: {x}\nFound relevant information from multiple sources...",
    "medical-assistant": lambda x: f"Medical assistant analysis: Based on the symptoms described in '{x}', here are some possible conditions...",
}

@app.post("/api/workflow/{workflow_id}")
async def run_workflow(workflow_id: str, input_data: WorkflowInput):
    if workflow_id not in WORKFLOW_RESPONSES:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    try:
        response = WORKFLOW_RESPONSES[workflow_id](input_data.input)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/agent/{agent_id}")
async def run_agent(agent_id: str, input_data: AgentInput):
    if agent_id not in AGENT_RESPONSES:
        raise HTTPException(status_code=404, detail="Agent not found")
    
    try:
        response = {"response": AGENT_RESPONSES[agent_id](input_data.message)}
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 