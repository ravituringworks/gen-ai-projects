from typing import List, Dict, Any, Callable, Optional, Union, Tuple
from abc import ABC, abstractmethod
from pydantic import BaseModel
import asyncio
import json
from enum import Enum

class ActionStatus(str, Enum):
    """Status of an action execution"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

class Action(BaseModel):
    """An action that can be executed by the agent"""
    id: str
    name: str
    description: str
    parameters: Dict[str, Any]
    status: ActionStatus = ActionStatus.PENDING
    result: Optional[Dict[str, Any]] = None

class Plan(BaseModel):
    """A plan consisting of actions to achieve a goal"""
    goal: str
    actions: List[Action]
    context: Dict[str, Any] = {}
    status: ActionStatus = ActionStatus.PENDING

class Tool(BaseModel):
    """A tool that can be used by the agent"""
    name: str
    description: str
    parameters: Dict[str, str]
    handler: Callable[[Dict[str, Any]], Any]

class Memory(BaseModel):
    """Agent's memory of past actions and results"""
    plans: List[Plan] = []
    action_history: List[Action] = []
    context: Dict[str, Any] = {}

class AutonomousAgent:
    """An agent that can plan and execute tasks autonomously"""
    
    def __init__(
        self,
        tools: List[Tool],
        llm_caller: Callable[[str], str],
        memory: Optional[Memory] = None
    ):
        self.tools = tools
        self.llm_caller = llm_caller
        self.memory = memory or Memory()
    
    async def _create_plan(
        self,
        goal: str,
        context: Dict[str, Any]
    ) -> Plan:
        """Create a plan to achieve a goal"""
        tools_desc = "\n".join([
            f"- {tool.name}: {tool.description}\n  Parameters: {tool.parameters}"
            for tool in self.tools
        ])
        
        prompt = (
            "Create a plan to achieve the following goal. Use available tools "
            "and break down the goal into specific actions.\n\n"
            f"Goal: {goal}\n\n"
            f"Context: {json.dumps(context, indent=2)}\n\n"
            f"Available Tools:\n{tools_desc}\n\n"
            "Previous Actions:\n" +
            "\n".join([
                f"- {action.name}: {action.status.value}"
                for action in self.memory.action_history[-5:]  # Last 5 actions
            ]) + "\n\n"
            "Respond with a plan in JSON format:\n"
            "{\n"
            '  "actions": [\n'
            "    {\n"
            '      "id": "action-1",\n'
            '      "name": "tool_name",\n'
            '      "description": "what this action will do",\n'
            '      "parameters": {}\n'
            "    }\n"
            "  ]\n"
            "}"
        )
        
        try:
            response = await self.llm_caller(prompt)
            plan_data = json.loads(response)
            return Plan(
                goal=goal,
                actions=[Action(**action) for action in plan_data["actions"]],
                context=context
            )
        except Exception as e:
            raise Exception(f"Error creating plan: {str(e)}")
    
    def _get_tool(self, name: str) -> Optional[Tool]:
        """Get a tool by name"""
        return next((t for t in self.tools if t.name == name), None)
    
    async def _execute_action(self, action: Action) -> Action:
        """Execute a single action"""
        try:
            # Get the tool
            tool = self._get_tool(action.name)
            if not tool:
                raise ValueError(f"Tool not found: {action.name}")
            
            # Update status
            action.status = ActionStatus.IN_PROGRESS
            
            # Execute tool
            result = await tool.handler(action.parameters)
            
            # Update action with result
            action.status = ActionStatus.COMPLETED
            action.result = result
            
            # Add to history
            self.memory.action_history.append(action)
            
            return action
            
        except Exception as e:
            action.status = ActionStatus.FAILED
            action.result = {"error": str(e)}
            self.memory.action_history.append(action)
            return action
    
    async def _evaluate_progress(
        self,
        plan: Plan,
        completed_actions: List[Action]
    ) -> Tuple[bool, str]:
        """Evaluate progress and decide if plan needs adjustment"""
        prompt = (
            "Evaluate the progress towards the goal and decide if the plan "
            "needs adjustment.\n\n"
            f"Goal: {plan.goal}\n\n"
            "Completed Actions:\n" +
            "\n".join([
                f"- {action.name}: {json.dumps(action.result, indent=2)}"
                for action in completed_actions
            ]) + "\n\n"
            "Respond in JSON format:\n"
            "{\n"
            '  "goal_achieved": true/false,\n'
            '  "reasoning": "explanation"\n'
            "}"
        )
        
        try:
            response = await self.llm_caller(prompt)
            eval_data = json.loads(response)
            return eval_data["goal_achieved"], eval_data["reasoning"]
        except Exception as e:
            raise Exception(f"Error evaluating progress: {str(e)}")
    
    async def _adjust_plan(
        self,
        plan: Plan,
        completed_actions: List[Action],
        evaluation_reason: str
    ) -> Plan:
        """Adjust the plan based on progress and results"""
        prompt = (
            "Adjust the plan based on completed actions and evaluation. "
            "Create new actions to achieve the goal.\n\n"
            f"Goal: {plan.goal}\n\n"
            "Completed Actions:\n" +
            "\n".join([
                f"- {action.name}: {json.dumps(action.result, indent=2)}"
                for action in completed_actions
            ]) + "\n\n"
            f"Evaluation: {evaluation_reason}\n\n"
            "Available Tools:\n" +
            "\n".join([
                f"- {tool.name}: {tool.description}"
                for tool in self.tools
            ]) + "\n\n"
            "Respond with adjusted plan in JSON format:\n"
            "{\n"
            '  "actions": [\n'
            "    {\n"
            '      "id": "action-1",\n'
            '      "name": "tool_name",\n'
            '      "description": "what this action will do",\n'
            '      "parameters": {}\n'
            "    }\n"
            "  ]\n"
            "}"
        )
        
        try:
            response = await self.llm_caller(prompt)
            plan_data = json.loads(response)
            return Plan(
                goal=plan.goal,
                actions=[Action(**action) for action in plan_data["actions"]],
                context=plan.context
            )
        except Exception as e:
            raise Exception(f"Error adjusting plan: {str(e)}")
    
    async def execute(
        self,
        goal: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[Action]:
        """Execute a goal autonomously"""
        context = context or {}
        completed_actions = []
        
        try:
            # Create initial plan
            plan = await self._create_plan(goal, context)
            self.memory.plans.append(plan)
            
            while True:
                # Execute all actions in current plan
                for action in plan.actions:
                    if action.status == ActionStatus.PENDING:
                        action = await self._execute_action(action)
                        if action.status == ActionStatus.COMPLETED:
                            completed_actions.append(action)
                
                # Evaluate progress
                goal_achieved, reason = await self._evaluate_progress(
                    plan,
                    completed_actions
                )
                
                if goal_achieved:
                    break
                
                # Adjust plan if needed
                plan = await self._adjust_plan(
                    plan,
                    completed_actions,
                    reason
                )
                self.memory.plans.append(plan)
            
            return completed_actions
            
        except Exception as e:
            raise Exception(f"Error executing goal: {str(e)}")

class AgentBuilder:
    """Helper class to build autonomous agents"""
    
    def __init__(self):
        self.tools: List[Tool] = []
        self.memory: Optional[Memory] = None
    
    def add_tool(
        self,
        name: str,
        description: str,
        parameters: Dict[str, str],
        handler: Callable[[Dict[str, Any]], Any]
    ) -> 'AgentBuilder':
        """Add a tool to the agent"""
        self.tools.append(
            Tool(
                name=name,
                description=description,
                parameters=parameters,
                handler=handler
            )
        )
        return self
    
    def with_memory(self, memory: Memory) -> 'AgentBuilder':
        """Set agent's memory"""
        self.memory = memory
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str]
    ) -> AutonomousAgent:
        """Build the agent"""
        return AutonomousAgent(
            tools=self.tools,
            llm_caller=llm_caller,
            memory=self.memory
        ) 