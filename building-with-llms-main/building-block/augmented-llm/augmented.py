from typing import List, Optional, Dict, Any
from abc import ABC, abstractmethod
import asyncio
import json

class Tool:
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description

    @abstractmethod
    async def execute(self, **kwargs) -> str:
        pass

class AugmentedLLM:
    def __init__(
        self,
        provider: str,
        api_key: Optional[str] = None,
        tools: Optional[List[Tool]] = None,
        enable_memory: bool = False
    ):
        self.provider = provider
        self.api_key = api_key or self._get_api_key()
        self.tools = tools or []
        self.memory = [] if enable_memory else None
        self.client = self._initialize_client()

    def _get_api_key(self) -> str:
        """Get API key from environment variables based on provider"""
        import os
        key_mapping = {
            "anthropic": "ANTHROPIC_API_KEY",
            "openai": "OPENAI_API_KEY",
        }
        key = os.getenv(key_mapping.get(self.provider, ""))
        if not key:
            raise ValueError(f"No API key found for provider {self.provider}")
        return key

    def _initialize_client(self):
        """Initialize the appropriate client based on provider"""
        if self.provider == "anthropic":
            from anthropic import Anthropic
            return Anthropic(api_key=self.api_key)
        elif self.provider == "openai":
            from openai import OpenAI
            return OpenAI(api_key=self.api_key)
        else:
            raise ValueError(f"Unsupported provider: {self.provider}")

    def _format_tools_for_prompt(self) -> str:
        """Format tools into a string for the prompt"""
        if not self.tools:
            return ""
        
        tool_descriptions = []
        for tool in self.tools:
            tool_descriptions.append(f"- {tool.name}: {tool.description}")
        
        return "Available tools:\n" + "\n".join(tool_descriptions)

    def _format_memory_for_prompt(self) -> str:
        """Format memory into a string for the prompt"""
        if not self.memory:
            return ""
        
        return "Previous conversation:\n" + "\n".join(self.memory)

    async def process(
        self,
        input_text: str,
        temperature: float = 0.7,
        max_tokens: int = 1000
    ) -> str:
        """Process input text using the augmented LLM"""
        # Construct the prompt with available tools and memory
        system_prompt = (
            "You are an AI assistant with access to tools and memory. "
            f"{self._format_tools_for_prompt()}\n"
            f"{self._format_memory_for_prompt()}"
        )

        try:
            if self.provider == "anthropic":
                response = await self._process_anthropic(
                    system_prompt,
                    input_text,
                    temperature,
                    max_tokens
                )
            elif self.provider == "openai":
                response = await self._process_openai(
                    system_prompt,
                    input_text,
                    temperature,
                    max_tokens
                )
            
            # Update memory if enabled
            if self.memory is not None:
                self.memory.append(f"User: {input_text}")
                self.memory.append(f"Assistant: {response}")
            
            return response

        except Exception as e:
            raise Exception(f"Error processing input: {str(e)}")

    async def _process_anthropic(
        self,
        system_prompt: str,
        input_text: str,
        temperature: float,
        max_tokens: int
    ) -> str:
        """Process using Anthropic's Claude"""
        response = await self.client.messages.create(
            model="claude-3-opus-20240229",
            max_tokens=max_tokens,
            temperature=temperature,
            system=system_prompt,
            messages=[{"role": "user", "content": input_text}]
        )
        return response.content[0].text

    async def _process_openai(
        self,
        system_prompt: str,
        input_text: str,
        temperature: float,
        max_tokens: int
    ) -> str:
        """Process using OpenAI's API"""
        response = await self.client.chat.completions.create(
            model="gpt-4-turbo-preview",
            temperature=temperature,
            max_tokens=max_tokens,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": input_text}
            ]
        )
        return response.choices[0].message.content