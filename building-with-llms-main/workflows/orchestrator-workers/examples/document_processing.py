import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv
import anthropic
from ..orchestrator import OrchestratorBuilder

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a helpful task decomposition assistant.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

# Worker handlers for different document processing tasks
async def handle_text_extraction(data: Dict[str, Any]) -> Dict[str, Any]:
    """Extract text from document (mock implementation)"""
    document = data["document"]
    return {
        "text": f"Extracted text from {document}",
        "pages": 5,
        "language": "en"
    }

async def handle_language_detection(data: Dict[str, Any]) -> Dict[str, Any]:
    """Detect language of text"""
    text = data["text"]
    return {
        "language": "en",
        "confidence": 0.95
    }

async def handle_summarization(data: Dict[str, Any]) -> Dict[str, Any]:
    """Summarize text content"""
    text = data["text"]
    return {
        "summary": f"Summary of: {text}",
        "length": "medium"
    }

async def handle_topic_extraction(data: Dict[str, Any]) -> Dict[str, Any]:
    """Extract main topics from text"""
    text = data["text"]
    return {
        "topics": ["topic1", "topic2", "topic3"],
        "confidence_scores": [0.9, 0.8, 0.7]
    }

async def handle_sentiment_analysis(data: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze sentiment of text"""
    text = data["text"]
    return {
        "sentiment": "positive",
        "score": 0.8,
        "aspects": {
            "tone": "professional",
            "emotion": "confident"
        }
    }

async def handle_formatting(data: Dict[str, Any]) -> Dict[str, Any]:
    """Format the final document analysis report"""
    return {
        "report": {
            "summary": data["summary"],
            "topics": data["topics"],
            "sentiment": data["sentiment"],
            "language": data["language"]
        },
        "format": "json"
    }

async def main():
    # Load environment variables
    load_dotenv()
    
    # Build the document processor
    processor = (
        OrchestratorBuilder()
        .add_worker(
            name="extractor",
            task_types=["text_extraction"],
            handler=handle_text_extraction,
            concurrency_limit=2
        )
        .add_worker(
            name="language_detector",
            task_types=["language_detection"],
            handler=handle_language_detection,
            concurrency_limit=1
        )
        .add_worker(
            name="summarizer",
            task_types=["summarization"],
            handler=handle_summarization,
            concurrency_limit=1
        )
        .add_worker(
            name="topic_extractor",
            task_types=["topic_extraction"],
            handler=handle_topic_extraction,
            concurrency_limit=1
        )
        .add_worker(
            name="sentiment_analyzer",
            task_types=["sentiment_analysis"],
            handler=handle_sentiment_analysis,
            concurrency_limit=1
        )
        .add_worker(
            name="formatter",
            task_types=["formatting"],
            handler=handle_formatting,
            concurrency_limit=1
        )
        .build(llm_caller=llm_call)
    )
    
    # Example document to process
    document = {
        "document": "sample_document.pdf",
        "options": {
            "include_summary": True,
            "include_topics": True,
            "include_sentiment": True
        }
    }
    
    try:
        # Process document
        print("\nProcessing document...")
        results = await processor.execute(document)
        
        # Print results
        print("\nProcessing Results:")
        for task_id, result in results.items():
            print(f"\n{task_id}:")
            print(result)
            
    except Exception as e:
        print(f"Error processing document: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 