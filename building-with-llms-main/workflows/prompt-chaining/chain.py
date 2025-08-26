from typing import List, Dict, Any, Optional, Callable
from abc import ABC, abstractmethod
import asyncio
from pydantic import BaseModel

class ChainStep(BaseModel):
    """A single step in a prompt chain"""
    name: str
    prompt_template: str
    output_key: str
    input_keys: List[str] = []
    
    def format_prompt(self, context: Dict[str, Any]) -> str:
        """Format the prompt template with context values"""
        try:
            return self.prompt_template.format(**context)
        except KeyError as e:
            missing_key = str(e).strip("'")
            raise ValueError(
                f"Missing required input '{missing_key}' for step '{self.name}'"
            )

class PromptChain:
    """A chain of prompt steps that process sequentially"""
    
    def __init__(
        self,
        steps: List[ChainStep],
        llm_caller: Callable[[str], str],
        initial_context: Optional[Dict[str, Any]] = None
    ):
        self.steps = steps
        self.llm_caller = llm_caller
        self.context = initial_context or {}
        self._validate_chain()
    
    def _validate_chain(self):
        """Validate that the chain's input/output dependencies are satisfied"""
        available_keys = set(self.context.keys())
        
        for step in self.steps:
            # Check if all required inputs are available
            missing_inputs = [
                key for key in step.input_keys 
                if key not in available_keys
            ]
            if missing_inputs:
                raise ValueError(
                    f"Step '{step.name}' requires inputs {missing_inputs} "
                    f"but only {available_keys} are available"
                )
            
            # Add this step's output to available keys
            available_keys.add(step.output_key)
    
    async def execute(self) -> Dict[str, Any]:
        """Execute the chain and return the final context"""
        for step in self.steps:
            # Format prompt with current context
            prompt = step.format_prompt(self.context)
            
            # Call LLM
            response = await self.llm_caller(prompt)
            
            # Update context with response
            self.context[step.output_key] = response
        
        return self.context

class ChainBuilder:
    """Helper class to build prompt chains"""
    
    def __init__(self):
        self.steps: List[ChainStep] = []
        
    def add_step(
        self,
        name: str,
        prompt_template: str,
        output_key: str,
        input_keys: Optional[List[str]] = None
    ) -> 'ChainBuilder':
        """Add a step to the chain"""
        self.steps.append(
            ChainStep(
                name=name,
                prompt_template=prompt_template,
                output_key=output_key,
                input_keys=input_keys or []
            )
        )
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str],
        initial_context: Optional[Dict[str, Any]] = None
    ) -> PromptChain:
        """Build the final chain"""
        return PromptChain(
            steps=self.steps,
            llm_caller=llm_caller,
            initial_context=initial_context
        ) 