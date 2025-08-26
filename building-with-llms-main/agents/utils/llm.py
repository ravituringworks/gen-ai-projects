"""
LLM Caller Utility

A utility class for making calls to various LLM APIs with consistent interface.
"""

import os
from typing import Dict, List, Optional, Union

import anthropic
from openai import OpenAI
from google.cloud import aiplatform
from azure.ai.ml import MLClient

class LLMCaller:
    """A utility class for making LLM API calls."""
    
    @staticmethod
    def get_client(provider: str = None):
        """Get the appropriate LLM client based on environment configuration."""
        if not provider:
            # Determine provider based on available API keys
            if os.getenv("ANTHROPIC_API_KEY"):
                provider = "anthropic"
            elif os.getenv("OPENAI_API_KEY"):
                provider = "openai"
            elif os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
                provider = "google"
            elif os.getenv("AZURE_OPENAI_API_KEY"):
                provider = "azure"
            else:
                raise ValueError("No LLM API credentials found in environment")
        
        if provider == "anthropic":
            return anthropic.Anthropic()
        elif provider == "openai":
            return OpenAI()
        elif provider == "google":
            return aiplatform.init()
        elif provider == "azure":
            return MLClient.from_config()
        else:
            raise ValueError(f"Unsupported LLM provider: {provider}")
    
    @staticmethod
    def get_default_model(provider: str) -> str:
        """Get the default model for a provider."""
        defaults = {
            "anthropic": "claude-3-opus-20240229",
            "openai": "gpt-4-turbo-preview",
            "google": "text-bison@002",
            "azure": "gpt-4"
        }
        return os.getenv(f"{provider.upper()}_DEFAULT_MODEL", defaults[provider])
    
    @staticmethod
    async def call(
        system: str,
        user: str,
        provider: str = None,
        model: str = None,
        temperature: float = 0.7,
        max_tokens: int = 1000,
        stop: Optional[Union[str, List[str]]] = None
    ) -> str:
        """
        Make a call to an LLM API.
        
        Args:
            system: System message/prompt
            user: User message/prompt
            provider: LLM provider (anthropic, openai, google, azure)
            model: Model to use (defaults to provider's default)
            temperature: Sampling temperature (0.0 to 1.0)
            max_tokens: Maximum tokens in response
            stop: Optional stop sequence(s)
            
        Returns:
            The LLM's response text
        """
        client = LLMCaller.get_client(provider)
        provider = provider or ("anthropic" if isinstance(client, anthropic.Anthropic) else
                              "openai" if isinstance(client, OpenAI) else
                              "google" if str(client.__class__).startswith("google") else
                              "azure")
        
        model = model or LLMCaller.get_default_model(provider)
        
        if provider == "anthropic":
            response = await client.messages.create(
                model=model,
                max_tokens=max_tokens,
                temperature=temperature,
                system=system,
                messages=[{"role": "user", "content": user}],
                stop_sequences=stop
            )
            return response.content[0].text
            
        elif provider == "openai":
            response = await client.chat.completions.create(
                model=model,
                temperature=temperature,
                max_tokens=max_tokens,
                messages=[
                    {"role": "system", "content": system},
                    {"role": "user", "content": user}
                ],
                stop=stop
            )
            return response.choices[0].message.content
            
        elif provider == "google":
            response = await client.predict_text(
                model=model,
                temperature=temperature,
                max_output_tokens=max_tokens,
                prompt=f"{system}\n\n{user}",
                stop_sequences=stop
            )
            return response.text
            
        elif provider == "azure":
            response = await client.chat.completions.create(
                deployment_name=model,
                temperature=temperature,
                max_tokens=max_tokens,
                messages=[
                    {"role": "system", "content": system},
                    {"role": "user", "content": user}
                ],
                stop=stop
            )
            return response.choices[0].message.content
            
        else:
            raise ValueError(f"Unsupported LLM provider: {provider}")
            
    @staticmethod
    def format_prompt(template: str, **kwargs) -> str:
        """Format a prompt template with variables."""
        return template.format(**kwargs) 