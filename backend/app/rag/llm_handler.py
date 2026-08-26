import json
import re
from typing import Dict, Any, Tuple
import google.generativeai as genai

class LLMHandler:
    """Handles all Gemini Flash interactions."""
    
    def __init__(self, api_key: str, model_name: str = "gemini-1.5-flash"):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(model_name)
        
    def classify_intent(self, message: str) -> str:
        """Classify message as swap_request or policy_query."""
        prompt = f"""
        Classify the following student message into one of these intents:
        1. swap_request - If they want to post a room swap request
        2. policy_query - If they ask about hostel rules/policies
        
        Message: "{message}"
        
        Return ONLY the intent name (swap_request or policy_query).
        """
        
        response = self.model.generate_content(prompt)
        intent = response.text.strip().lower()
        
        if "swap" in intent:
            return "swap_request"
        else:
            return "policy_query"
    def parse_swap_request(self, message: str) -> Dict[str, Any]:
        """Extract structured data from swap request message."""
        prompt = f"""
        Extract the following details from this hostel swap request message.
        Return ONLY valid JSON.
        
        Message: "{message}"
        
        Required fields:
        - current_hostel: (BH-1, BH-2, BH-3, GH-1, GH-2, GH-3)
        - current_ac: (true or false)
        - current_seater: (2, 3, 4, or 5)
        - desired_hostel: (BH-1, BH-2, BH-3, GH-1, GH-2, GH-3)
        - desired_ac: (true, false, or null if not mentioned)
        - desired_seater: (2, 3, 4, 5, or null if not mentioned)
        
        Return JSON only, no other text.
        """
        response = self.model.generate_content(prompt)
        
        # Extract JSON from response
        try:
            data = json.loads(response.text)
        except:
            # Try to extract JSON with regex
            json_match = re.search(r'\{.*\}', response.text, re.DOTALL)
            if json_match:
                data = json.loads(json_match.group())
            else:
                return {"error": "Failed to parse request"}
        
        return data
    
    def generate_rag_answer(self, query: str, context_chunks: list) -> Tuple[str, str]:
        """Generate answer using retrieved context chunks."""
        if not context_chunks:
            return "I don't have that information in the hostel policy documents.", None
        
        # Build context from chunks
        context = "\n\n".join([chunk["text"] for chunk in context_chunks])
        
        # Get sources
        sources = list(set([chunk.get("metadata", {}).get("source", "Unknown") for chunk in context_chunks]))
        source_str = f"Source: {', '.join(sources)}" if sources else None
        
        
        prompt = f"""
        Answer the question based ONLY on the following context.
        If the answer is not in the context, say "I don't have that information in the hostel policy documents."
        Keep your answer clear and concise.
        
        CONTEXT:
        {context}
        
        QUESTION: {query}
        
        ANSWER:
        """
        
        response = self.model.generate_content(prompt)
        answer = response.text.strip()
        
        return answer, source_str
    
    def detect_language(self, text: str) -> str:
        """Detect the language of the input text."""
        prompt = f"""
        Detect the language of this text. Return ONLY the language code:
        - en: English
        - hi: Hindi
        - ta: Tamil
        - te: Telugu
        - other: For any other language
        
        Text: "{text}"
        """
        
        response = self.model.generate_content(prompt)
        lang = response.text.strip().lower()
        
        if lang in ["en", "hi", "ta", "te"]:
            return lang
        return "en"
    
    def translate_response(self, text: str, target_lang: str) -> str:
        """Translate response to target language."""
        if target_lang == "en":
            return text
        
        prompt = f"""
        Translate the following text to {target_lang}.
        Return ONLY the translation, no other text.
        
        Text: {text}
        """
        
        response = self.model.generate_content(prompt)
        return response.text.strip()
    
    