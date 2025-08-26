import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv
import anthropic
from ..agent import DomainAgentBuilder, DomainMemory, DomainKnowledge

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a medical diagnosis assistant.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

# Domain-specific tool handlers
async def handle_symptom_analysis(params: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze patient symptoms"""
    symptoms = params["symptoms"]
    return {
        "severity": "moderate",
        "urgency": "non-emergency",
        "possible_conditions": [
            "condition1",
            "condition2",
            "condition3"
        ],
        "risk_factors": [
            "risk1",
            "risk2"
        ]
    }

async def handle_medical_history_check(params: Dict[str, Any]) -> Dict[str, Any]:
    """Check patient medical history"""
    patient_id = params["patient_id"]
    return {
        "previous_conditions": [
            "condition1",
            "condition2"
        ],
        "allergies": [
            "allergy1",
            "allergy2"
        ],
        "medications": [
            "medication1",
            "medication2"
        ]
    }

async def handle_drug_interaction_check(params: Dict[str, Any]) -> Dict[str, Any]:
    """Check for potential drug interactions"""
    medications = params["medications"]
    return {
        "interactions": [
            {
                "drugs": ["drug1", "drug2"],
                "severity": "high",
                "recommendation": "avoid combination"
            }
        ],
        "alternatives": [
            "alt_drug1",
            "alt_drug2"
        ]
    }

async def handle_treatment_recommendation(params: Dict[str, Any]) -> Dict[str, Any]:
    """Generate treatment recommendations"""
    condition = params["condition"]
    patient_data = params["patient_data"]
    return {
        "primary_treatment": "treatment1",
        "alternatives": [
            "treatment2",
            "treatment3"
        ],
        "lifestyle_changes": [
            "change1",
            "change2"
        ],
        "follow_up": "2 weeks"
    }

# Domain-specific constraints
def validate_patient_data(params: Dict[str, Any]) -> bool:
    """Validate patient data completeness"""
    required_fields = ["age", "gender", "symptoms"]
    return all(field in params for field in required_fields)

def validate_medication_safety(params: Dict[str, Any]) -> bool:
    """Validate medication safety"""
    if "medications" not in params:
        return True
    # Mock safety check
    unsafe_medications = ["unsafe_drug1", "unsafe_drug2"]
    return not any(med in unsafe_medications for med in params["medications"])

# Medical domain knowledge
medical_knowledge = {
    "facts": {
        "common_conditions": [
            "hypertension",
            "diabetes",
            "asthma"
        ],
        "vital_signs": {
            "normal_bp": "120/80",
            "normal_temp": "98.6F",
            "normal_hr": "60-100"
        }
    },
    "rules": {
        "emergency_symptoms": "Chest pain, difficulty breathing, or severe bleeding require immediate emergency care",
        "prescription_requirements": "Controlled substances require proper documentation and authorization",
        "follow_up_timing": "Critical conditions require follow-up within 24-48 hours"
    },
    "terminology": {
        "bp": "Blood Pressure",
        "hr": "Heart Rate",
        "bmi": "Body Mass Index"
    },
    "relationships": {
        "diabetes": ["blood_sugar", "insulin", "diet"],
        "hypertension": ["blood_pressure", "sodium", "stress"]
    }
}

# Domain-specific behaviors
diagnosis_behavior = {
    "name": "comprehensive_diagnosis",
    "description": "Perform comprehensive diagnosis when multiple symptoms present",
    "trigger_conditions": {
        "symptom_count": ">3",
        "severity": "high"
    },
    "action_template": {
        "name": "detailed_analysis",
        "parameters": {
            "include_specialists": True,
            "run_additional_tests": True
        }
    }
}

async def main():
    # Load environment variables
    load_dotenv()
    
    # Initialize domain memory
    memory = DomainMemory(
        context={
            "facility_type": "primary_care",
            "available_specialists": ["cardiology", "neurology", "endocrinology"],
            "emergency_protocols": ["protocol1", "protocol2"]
        }
    )
    
    # Build the medical assistant
    assistant = (
        DomainAgentBuilder("medical_diagnosis")
        .add_tool(
            name="symptom_analysis",
            description="Analyze patient symptoms and determine possible conditions",
            parameters={
                "symptoms": "list of symptoms"
            },
            handler=handle_symptom_analysis
        )
        .add_tool(
            name="medical_history",
            description="Check patient medical history",
            parameters={
                "patient_id": "patient identifier"
            },
            handler=handle_medical_history_check
        )
        .add_tool(
            name="drug_interaction",
            description="Check for potential drug interactions",
            parameters={
                "medications": "list of medications"
            },
            handler=handle_drug_interaction_check
        )
        .add_tool(
            name="treatment_recommendation",
            description="Generate treatment recommendations",
            parameters={
                "condition": "diagnosed condition",
                "patient_data": "patient information"
            },
            handler=handle_treatment_recommendation
        )
        .add_constraint(
            name="patient_data_validation",
            description="Ensure all required patient data is provided",
            validation_fn=validate_patient_data,
            error_message="Missing required patient information"
        )
        .add_constraint(
            name="medication_safety",
            description="Ensure medication safety",
            validation_fn=validate_medication_safety,
            error_message="Unsafe medication detected"
        )
        .add_behavior(
            name=diagnosis_behavior["name"],
            description=diagnosis_behavior["description"],
            trigger_conditions=diagnosis_behavior["trigger_conditions"],
            action_template=diagnosis_behavior["action_template"]
        )
        .with_knowledge(**medical_knowledge)
        .with_memory(memory)
        .build(llm_caller=llm_call)
    )
    
    # Example cases to diagnose
    cases = [
        {
            "goal": "Diagnose patient with symptoms: fever, cough, fatigue",
            "context": {
                "patient_data": {
                    "age": 45,
                    "gender": "F",
                    "symptoms": ["fever", "cough", "fatigue"],
                    "vitals": {
                        "temperature": "101.2F",
                        "blood_pressure": "128/82",
                        "heart_rate": 88
                    }
                }
            }
        },
        {
            "goal": "Recommend treatment for diagnosed hypertension",
            "context": {
                "patient_data": {
                    "age": 62,
                    "gender": "M",
                    "condition": "hypertension",
                    "medications": ["lisinopril"],
                    "blood_pressure": "158/94"
                }
            }
        }
    ]
    
    # Process cases
    for case in cases:
        print(f"\n{'-' * 50}")
        print(f"Processing Case: {case['goal']}")
        print(f"{'-' * 50}")
        
        try:
            # Execute diagnosis/treatment
            actions = await assistant.execute(
                goal=case["goal"],
                context=case["context"]
            )
            
            # Print results
            print("\nCompleted Actions:")
            for action in actions:
                print(f"\n{action.description}:")
                print(f"Tool: {action.name}")
                print(f"Result: {action.result}")
                
        except Exception as e:
            print(f"Error processing case: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 