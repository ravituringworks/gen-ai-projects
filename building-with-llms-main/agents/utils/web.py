"""
Web Utilities

Utilities for web search and webpage content extraction.
"""

import os
from typing import Dict, List, Optional
import aiohttp
from bs4 import BeautifulSoup
from duckduckgo_search import AsyncDDGS

from .llm import LLMCaller

class WebSearchTool:
    """A tool for performing web searches."""
    
    def __init__(self, name: str, description: str, parameters: Dict):
        self.name = name
        self.description = description
        self.parameters = parameters
        
    async def __call__(self, query: str, num_results: int = 3) -> Dict:
        """
        Perform a web search using DuckDuckGo.
        
        Args:
            query: Search query
            num_results: Number of results to return
            
        Returns:
            Dict containing search results
        """
        async with AsyncDDGS() as ddgs:
            results = []
            async for r in ddgs.text(query, max_results=num_results):
                results.append({
                    "title": r["title"],
                    "snippet": r["body"],
                    "url": r["link"]
                })
            return {"results": results}

class WebpageReaderTool:
    """A tool for reading and extracting content from webpages."""
    
    def __init__(self, name: str, description: str, parameters: Dict):
        self.name = name
        self.description = description
        self.parameters = parameters
        
    async def __call__(self, url: str) -> Dict:
        """
        Read and extract content from a webpage.
        
        Args:
            url: URL of the webpage to read
            
        Returns:
            Dict containing extracted content and metadata
        """
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                if response.status != 200:
                    raise ValueError(f"Failed to fetch URL: {url}")
                    
                html = await response.text()
                soup = BeautifulSoup(html, "html.parser")
                
                # Remove script and style elements
                for script in soup(["script", "style"]):
                    script.decompose()
                
                # Extract text content
                text = soup.get_text()
                
                # Clean up whitespace
                lines = (line.strip() for line in text.splitlines())
                chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
                text = " ".join(chunk for chunk in chunks if chunk)
                
                # Extract metadata
                title = soup.title.string if soup.title else ""
                meta_desc = soup.find("meta", attrs={"name": "description"})
                description = meta_desc["content"] if meta_desc else ""
                
                # Use LLM to clean and structure content
                cleaned_content = await LLMCaller.call(
                    system="You are a helpful assistant that cleans and structures webpage content.",
                    user=f"Clean and structure the following webpage content, removing any irrelevant parts like navigation, footers, etc:\n\n{text[:2000]}..."  # Limit content length
                )
                
                return {
                    "title": title,
                    "description": description,
                    "content": cleaned_content,
                    "url": url
                } 