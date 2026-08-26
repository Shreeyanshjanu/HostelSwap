"""
app/rag/llm_handler.py
-----------------------
Handles all LLM interactions. Supports Gemini (default) and Groq.
Existing method signatures preserved for backward compat with pipeline.py.
"""
import json, re, os, logging
from typing import Dict, Any, Tuple, List, Optional

logger = logging.getLogger(__name__)

GEMINI_AVAILABLE = False
GROQ_AVAILABLE = False

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    pass

try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    pass


class LLMHandler:
    """Handles all LLM interactions. Supports Gemini (default) and Groq."""

    def __init__(self, api_key: str, model_name: str = "gemini-2.0-flash", provider: str = "gemini"):
        self.provider = provider
        self.model_name = model_name
        self._client = None

        if provider == "gemini" and GEMINI_AVAILABLE and api_key:
            genai.configure(api_key=api_key)
            self._client = genai.GenerativeModel(model_name)
        elif provider == "groq" and GROQ_AVAILABLE and api_key:
            self._client = Groq(api_key=api_key)
        else:
            logger.warning(f"LLM provider '{provider}' not available or missing API key. Chatbot disabled.")

    def _generate(self, prompt: str) -> str:
        if self._client is None:
            return "LLM not configured."
        if self.provider == "gemini":
            response = self._client.generate_content(prompt)
            return response.text.strip()
        elif self.provider == "groq":
            response = self._client.chat.completions.create(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
            )
            return response.choices[0].message.content.strip()
        return ""

    def classify_intent(self, message: str) -> str:
        prompt = f"""Classify this student message as one of: swap_request, policy_query, general.
Return ONLY the intent name.
Message: "{message}"
Intent:"""
        result = self._generate(prompt).lower()
        if "swap" in result: return "swap_request"
        if "policy" in result: return "policy_query"
        return "general"

    def parse_swap_request(self, message: str, gender: str, valid_hostels: List[str]) -> Dict[str, Any]:
        hostel_list = ", ".join(valid_hostels)
        prompt = f"""Extract hostel swap details from this message. Return ONLY valid JSON.
Message: "{message}"
Valid hostels for this student: {hostel_list}
JSON fields:
- current_hostel: one of [{hostel_list}]
- current_ac: true or false
- current_seater: 2, 3, 4, or 5
- desired_hostel: one of [{hostel_list}]
- desired_ac: true, false, or null if flexible
- desired_seater: 2, 3, 4, 5, or null if flexible
Return JSON only."""
        raw = self._generate(prompt)
        try:
            raw = re.sub(r"```json|```", "", raw).strip()
            return json.loads(raw)
        except Exception:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try: return json.loads(match.group())
                except: pass
            return {"error": "Failed to parse request"}

    def generate_rag_answer(self, query: str, context_chunks: list) -> Tuple[str, Optional[str]]:
        if not context_chunks:
            return "I don't have that information in the hostel policy documents.", None
        context = "\n\n".join([c["text"] for c in context_chunks])
        sources = list(set([c.get("metadata", {}).get("source", "Unknown") for c in context_chunks]))
        source_str = f"Source: {', '.join(sources)}" if sources else None
        prompt = f"""Answer based ONLY on this context. If not in context, say "I don't have that information in the hostel policy documents."
CONTEXT:
{context}
QUESTION: {query}
ANSWER:"""
        return self._generate(prompt), source_str

    def detect_language(self, text: str) -> str:
        prompt = f"""Detect the language of this text. Return ONLY: en, hi, ta, te, or other.
Text: "{text}"
Language code:"""
        lang = self._generate(prompt).strip().lower()
        return lang if lang in ["en", "hi", "ta", "te"] else "en"

    def translate_response(self, text: str, target_lang: str) -> str:
        if target_lang == "en":
            return text
        prompt = f"Translate this to {target_lang}. Return ONLY the translation:\n{text}"
        return self._generate(prompt)
