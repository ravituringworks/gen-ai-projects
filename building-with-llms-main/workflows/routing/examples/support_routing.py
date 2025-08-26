import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv
import anthropic
from ..router import RouterBuilder

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a helpful support ticket router.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

# Handler functions for different support routes
async def handle_technical_issue(data: Dict[str, Any]) -> str:
    return (
        f"Technical Support Response:\n"
        f"We'll help you resolve the {data.get('issue_type', 'issue')}. "
        f"Our technical team will investigate and respond within 24 hours."
    )

async def handle_billing_query(data: Dict[str, Any]) -> str:
    return (
        f"Billing Support Response:\n"
        f"We'll help you with your billing question about "
        f"{data.get('issue_type', 'billing')}. "
        f"Our billing team will review and respond shortly."
    )

async def handle_account_management(data: Dict[str, Any]) -> str:
    return (
        f"Account Management Response:\n"
        f"We'll help you manage your account settings for "
        f"{data.get('issue_type', 'your account')}. "
        f"Our account team will assist you promptly."
    )

async def handle_feature_request(data: Dict[str, Any]) -> str:
    return (
        f"Feature Request Response:\n"
        f"Thank you for your suggestion about {data.get('issue_type', 'feature')}. "
        f"Our product team will review your request."
    )

async def fallback_handler(data: Dict[str, Any]) -> str:
    return (
        f"General Support Response:\n"
        f"We've received your request and will route it to the appropriate team. "
        f"Someone will be in touch shortly."
    )

async def main():
    # Load environment variables
    load_dotenv()
    
    # Build the support router
    router = (
        RouterBuilder()
        .add_route(
            name="technical",
            description="Technical issues, bugs, and system problems",
            handler=handle_technical_issue,
            required_fields=["issue_type", "description"]
        )
        .add_route(
            name="billing",
            description="Billing inquiries, payments, and subscription issues",
            handler=handle_billing_query,
            required_fields=["issue_type", "description"]
        )
        .add_route(
            name="account",
            description="Account settings, access, and management",
            handler=handle_account_management,
            required_fields=["issue_type", "description"]
        )
        .add_route(
            name="feature",
            description="Feature requests and product suggestions",
            handler=handle_feature_request,
            required_fields=["issue_type", "description"]
        )
        .set_fallback(fallback_handler)
        .build(llm_caller=llm_call)
    )
    
    # Example support tickets
    tickets = [
        {
            "issue_type": "login_error",
            "description": "Can't log in to my account, keeps saying invalid password",
            "priority": "high"
        },
        {
            "issue_type": "subscription_renewal",
            "description": "Need help updating my credit card for monthly billing",
            "priority": "medium"
        },
        {
            "issue_type": "dark_mode",
            "description": "Would love to see a dark mode option in the dashboard",
            "priority": "low"
        },
        {
            "issue_type": "profile_settings",
            "description": "How do I change my notification preferences?",
            "priority": "medium"
        }
    ]
    
    # Process tickets
    for ticket in tickets:
        print(f"\nProcessing Ticket: {ticket}")
        try:
            response = await router.route(ticket)
            print(f"Response: {response}")
        except Exception as e:
            print(f"Error processing ticket: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 