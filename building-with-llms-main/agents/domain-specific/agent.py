from typing import List, Dict, Any, Callable, Optional, Union, Type
from pydantic import BaseModel, Field
from enum import Enum
import json
from ..autonomous-agent.agent import AutonomousAgent, Tool, Memory, Action, Plan, ActionStatus

class DomainConstraint(BaseModel):
    """Represents a domain-specific constraint"""
    name: str
    description: str
    validation_fn: Callable[[Dict[str, Any]], bool]
    error_message: str

class DomainKnowledge(BaseModel):
    """Represents domain-specific knowledge"""
    facts: Dict[str, Any] = {}
    rules: Dict[str, str] = {}
    terminology: Dict[str, str] = {}
    relationships: Dict[str, List[str]] = {}

class DomainBehavior(BaseModel):
    """Represents domain-specific behavior"""
    name: str
    description: str
    trigger_conditions: Dict[str, Any]
    action_template: Dict[str, Any]

class DomainMemory(Memory):
    """Extended memory with domain-specific information"""
    domain_knowledge: DomainKnowledge = Field(default_factory=DomainKnowledge)
    domain_specific_history: List[Dict[str, Any]] = []

class DomainSpecificAgent(AutonomousAgent):
    """An agent specialized for a specific domain"""
    
    def __init__(
        self,
        domain_name: str,
        tools: List[Tool],
        llm_caller: Callable[[str], str],
        constraints: List[DomainConstraint],
        behaviors: List[DomainBehavior],
        domain_knowledge: DomainKnowledge,
        memory: Optional[DomainMemory] = None
    ):
        super().__init__(tools, llm_caller, memory or DomainMemory())
        self.domain_name = domain_name
        self.constraints = constraints
        self.behaviors = behaviors
        self.domain_knowledge = domain_knowledge
    
    async def _validate_action(self, action: Action) -> Tuple[bool, Optional[str]]:
        """Validate action against domain constraints"""
        for constraint in self.constraints:
            try:
                if not constraint.validation_fn(action.parameters):
                    return False, constraint.error_message
            except Exception as e:
                return False, f"Error validating {constraint.name}: {str(e)}"
        return True, None
    
    async def _enrich_context(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Enrich context with domain-specific knowledge"""
        return {
            **context,
            "domain_knowledge": {
                "facts": self.domain_knowledge.facts,
                "rules": self.domain_knowledge.rules,
                "terminology": self.domain_knowledge.terminology,
                "relationships": self.domain_knowledge.relationships
            }
        }
    
    async def _check_behaviors(
        self,
        action: Action,
        context: Dict[str, Any]
    ) -> Optional[Action]:
        """Check if any domain-specific behaviors should be triggered"""
        for behavior in self.behaviors:
            matches = all(
                context.get(k) == v
                for k, v in behavior.trigger_conditions.items()
            )
            if matches:
                return Action(
                    id=f"{action.id}_behavior_{behavior.name}",
                    name=behavior.name,
                    description=behavior.description,
                    parameters=behavior.action_template
                )
        return None
    
    async def _create_plan(
        self,
        goal: str,
        context: Dict[str, Any]
    ) -> Plan:
        """Create a domain-aware plan"""
        # Enrich context with domain knowledge
        enriched_context = await self._enrich_context(context)
        
        # Add domain-specific prompt elements
        domain_prompt = (
            f"You are a specialized agent for the {self.domain_name} domain.\n"
            "Consider the following domain-specific knowledge:\n"
            f"Facts: {json.dumps(self.domain_knowledge.facts, indent=2)}\n"
            f"Rules: {json.dumps(self.domain_knowledge.rules, indent=2)}\n"
            f"Terminology: {json.dumps(self.domain_knowledge.terminology, indent=2)}\n"
            "Create a plan that adheres to domain constraints and leverages domain knowledge."
        )
        
        # Create plan with domain awareness
        plan = await super()._create_plan(
            goal=f"{domain_prompt}\n\nGoal: {goal}",
            context=enriched_context
        )
        
        return plan
    
    async def _execute_action(self, action: Action) -> Action:
        """Execute action with domain-specific validation and behaviors"""
        try:
            # Validate against domain constraints
            is_valid, error = await self._validate_action(action)
            if not is_valid:
                action.status = ActionStatus.FAILED
                action.result = {"error": error}
                return action
            
            # Check for triggered behaviors
            behavior_action = await self._check_behaviors(
                action,
                self.memory.context
            )
            if behavior_action:
                # Execute behavior action first
                behavior_result = await super()._execute_action(behavior_action)
                if behavior_result.status == ActionStatus.FAILED:
                    return behavior_result
            
            # Execute main action
            action = await super()._execute_action(action)
            
            # Record in domain-specific history
            if isinstance(self.memory, DomainMemory):
                self.memory.domain_specific_history.append({
                    "action": action.dict(),
                    "domain_context": self.memory.context
                })
            
            return action
            
        except Exception as e:
            action.status = ActionStatus.FAILED
            action.result = {"error": str(e)}
            return action

class DomainAgentBuilder:
    """Helper class to build domain-specific agents"""
    
    def __init__(self, domain_name: str):
        self.domain_name = domain_name
        self.tools: List[Tool] = []
        self.constraints: List[DomainConstraint] = []
        self.behaviors: List[DomainBehavior] = []
        self.domain_knowledge = DomainKnowledge()
        self.memory: Optional[DomainMemory] = None
    
    def add_tool(
        self,
        name: str,
        description: str,
        parameters: Dict[str, str],
        handler: Callable[[Dict[str, Any]], Any]
    ) -> 'DomainAgentBuilder':
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
    
    def add_constraint(
        self,
        name: str,
        description: str,
        validation_fn: Callable[[Dict[str, Any]], bool],
        error_message: str
    ) -> 'DomainAgentBuilder':
        """Add a domain constraint"""
        self.constraints.append(
            DomainConstraint(
                name=name,
                description=description,
                validation_fn=validation_fn,
                error_message=error_message
            )
        )
        return self
    
    def add_behavior(
        self,
        name: str,
        description: str,
        trigger_conditions: Dict[str, Any],
        action_template: Dict[str, Any]
    ) -> 'DomainAgentBuilder':
        """Add a domain-specific behavior"""
        self.behaviors.append(
            DomainBehavior(
                name=name,
                description=description,
                trigger_conditions=trigger_conditions,
                action_template=action_template
            )
        )
        return self
    
    def with_knowledge(
        self,
        facts: Dict[str, Any] = None,
        rules: Dict[str, str] = None,
        terminology: Dict[str, str] = None,
        relationships: Dict[str, List[str]] = None
    ) -> 'DomainAgentBuilder':
        """Add domain knowledge"""
        if facts:
            self.domain_knowledge.facts.update(facts)
        if rules:
            self.domain_knowledge.rules.update(rules)
        if terminology:
            self.domain_knowledge.terminology.update(terminology)
        if relationships:
            self.domain_knowledge.relationships.update(relationships)
        return self
    
    def with_memory(self, memory: DomainMemory) -> 'DomainAgentBuilder':
        """Set agent's memory"""
        self.memory = memory
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str]
    ) -> DomainSpecificAgent:
        """Build the domain-specific agent"""
        return DomainSpecificAgent(
            domain_name=self.domain_name,
            tools=self.tools,
            llm_caller=llm_caller,
            constraints=self.constraints,
            behaviors=self.behaviors,
            domain_knowledge=self.domain_knowledge,
            memory=self.memory
        ) 