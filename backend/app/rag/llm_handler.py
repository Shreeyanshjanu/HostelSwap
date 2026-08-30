# app/rag/llm_handler.py

import json
import re
import time
import os
from typing import Dict, Any, Tuple, List

from openai import OpenAI


class LLMHandler:
    """Handles all LLM interactions through Azure OpenAI v1."""

    def __init__(
        self,
        api_key: str,
        model_name: str = None,
        temperature: float = 0.6,
        azure_endpoint: str = None,
        azure_deployment: str = None,
    ):
        self.deployment = (
            azure_deployment
            or os.getenv("AZURE_OPENAI_DEPLOYMENT")
        )

        endpoint = (
            azure_endpoint
            or os.getenv("AZURE_OPENAI_ENDPOINT")
        )

        if not api_key or api_key == "dummy-key" or not endpoint or not self.deployment:
            print(
                " WARNING: Missing Azure OpenAI config "
                "(key/endpoint/deployment)!"
            )

            self.client = None

        else:
            try:
                # Azure OpenAI v1 uses the standard OpenAI client.
                # The endpoint should already contain /openai/v1/
                self.client = OpenAI(
                    api_key=api_key,
                    base_url=endpoint,
                )

                print(
                    " Azure OpenAI v1 client initialized "
                    f"with deployment: {self.deployment}"
                )

            except Exception as e:
                print(
                    f" Error initializing Azure OpenAI client: {e}"
                )

                self.client = None

        self.model_name = self.deployment
        self.temperature = temperature

    def _generate_content(
        self,
        prompt: str,
        temperature: float = None,
        max_retries: int = 3
    ) -> str:
        """
        Generate content using Azure OpenAI's
        OpenAI-compatible v1 API.
        """

        if not self.client:
            return (
                "ERROR: Azure OpenAI client not initialized. "
                "Please check your config."
            )

        last_error = None

        for attempt in range(max_retries):

            try:
                response = self.client.chat.completions.create(
                    model=self.deployment,
                    messages=[
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    temperature=(
                        temperature
                        if temperature is not None
                        else self.temperature
                    ),
                    top_p=0.9,
                )

                return response.choices[0].message.content

            except Exception as e:

                last_error = e
                error_str = str(e)

                is_rate_limit = (
                    "429" in error_str
                    or "rate limit" in error_str.lower()
                    or "quota" in error_str.lower()
                )

                if (
                    is_rate_limit
                    and attempt < max_retries - 1
                ):
                    wait_time = (2 ** attempt) * 1.5

                    print(
                        f"⏳ Rate limited by Azure OpenAI "
                        f"(attempt {attempt + 1}/{max_retries}). "
                        f"Retrying in {wait_time}s..."
                    )

                    time.sleep(wait_time)
                    continue

                else:
                    print(
                        f"Error generating content: {e}"
                    )

                    return f"ERROR: {str(e)}"

        return f"ERROR: {str(last_error)}"

    def classify_intent(self, message: str) -> str:
        """Classify message as swap_request or policy_query."""

        prompt = f"""
        Classify the following student message into one of these intents:

        1. swap_request - If they want to post a room swap request
        2. policy_query - If they ask about hostel rules/policies
        3. general - If it's a greeting or something else

        Message: "{message}"

        Return ONLY the intent name
        (swap_request, policy_query, or general).
        """

        response = self._generate_content(
            prompt,
            temperature=0.0
        )

        if "ERROR" in response:
            return "general"

        intent = response.strip().lower()

        if "swap" in intent:
            return "swap_request"

        elif "policy" in intent:
            return "policy_query"

        else:
            return "general"

    def parse_swap_request(
        self,
        message: str
    ) -> Dict[str, Any]:
        """Extract structured data from swap request message."""

        prompt = f"""
        Extract the following details from this hostel swap request message.

        Return ONLY valid JSON, no other text.

        Message: "{message}"

        Required fields:

        - current_hostel:
          (BH-1, BH-2, BH-3, GH-1, GH-2, GH-3)

        - current_ac:
          (true or false)

        - current_seater:
          (2, 3, 4, or 5)

        - desired_hostel:
          (BH-1, BH-2, BH-3, GH-1, GH-2, GH-3)

        - desired_ac:
          (true, false, or null if not mentioned)

        - desired_seater:
          (2, 3, 4, 5, or null if not mentioned)

        Return JSON only, no other text.
        """

        response = self._generate_content(
            prompt,
            temperature=0.0
        )

        if "ERROR" in response:
            return {
                "error": "Failed to parse request"
            }

        try:
            json_match = re.search(
                r'\{.*\}',
                response,
                re.DOTALL
            )

            if json_match:
                return json.loads(
                    json_match.group()
                )

            else:
                return {
                    "error": "Failed to parse request"
                }

        except Exception:
            return {
                "error": "Failed to parse request"
            }

    def generate_rag_answer(
        self,
        query: str,
        context_chunks: List[Dict]
    ) -> Tuple[str, str]:
        """Generate a conversational RAG answer."""

        if not context_chunks:
            return (
                "I don't have that information in the hostel "
                "policy documents — you might want to check "
                "with the Hostel Office directly.",
                None
            )

        context = "\n\n".join(
            [
                chunk["text"]
                for chunk in context_chunks
            ]
        )

        sources = list(
            set(
                [
                    chunk.get(
                        "metadata",
                        {}
                    ).get(
                        "source",
                        "Unknown"
                    )
                    for chunk in context_chunks
                ]
            )
        )

        source_str = (
            f"Source: {', '.join(sources)}"
            if sources
            else None
        )

        prompt = f"""
        You are a friendly, helpful assistant for HostelSwap,
        a college hostel room-swap platform.

        A student just asked you a question about hostel policy.

        Answer them the way a knowledgeable, approachable senior
        student or hostel warden's assistant would — warm, natural,
        and to the point.

        Rules:

        - Base your answer ONLY on the information in the CONTEXT.
        - Do not invent policy details.
        - If the context doesn't answer their question, say so
          naturally and suggest they check with the Hostel Office.
        - Vary your phrasing naturally.
        - Keep it conversational.
        - Use a sentence or two unless the question specifically
          requires steps.

        CONTEXT:
        {context}

        STUDENT'S QUESTION:
        {query}

        YOUR RESPONSE:
        """

        response = self._generate_content(
            prompt,
            temperature=0.6
        )

        if "ERROR" in response:
            return (
                "I couldn't generate a response right now. "
                "Please try again in a moment.",
                None
            )

        return response.strip(), source_str

    def generate_general_reply(
        self,
        message: str
    ) -> str:
        """Generate a natural conversational reply."""

        prompt = f"""
        You are a friendly assistant for HostelSwap,
        a college hostel room-swap platform.

        A student just sent you this message, which isn't a
        swap request or a policy question.

        Reply naturally and briefly, like a real person would
        in a chat app.

        If appropriate, mention that you can help with:

        - Posting a swap request
        - Answering hostel policy questions

        STUDENT'S MESSAGE:
        "{message}"

        YOUR RESPONSE:
        """

        response = self._generate_content(
            prompt,
            temperature=0.7
        )

        if "ERROR" in response:
            return (
                "Hi! I can help you post a swap request or "
                "answer questions about hostel policies. "
                "Try: 'I have BH-2 Non-AC 3-seater, want "
                "BH-1 AC 2-seater' or 'What is the hostel "
                "shift deadline?'"
            )

        return response.strip()

    def detect_language(
        self,
        text: str
    ) -> str:
        """Detect the language of the input text."""

        prompt = f"""
        Detect the language of this text.

        Return ONLY the language code:

        - en: English
        - hi: Hindi
        - ta: Tamil
        - te: Telugu

        Text: "{text}"
        """

        response = self._generate_content(
            prompt,
            temperature=0.0
        )

        if "ERROR" in response:
            return "en"

        lang = response.strip().lower()

        if lang in [
            "en",
            "hi",
            "ta",
            "te"
        ]:
            return lang

        return "en"

    def translate_response(
        self,
        text: str,
        target_lang: str
    ) -> str:
        """Translate response while preserving tone."""

        if target_lang == "en":
            return text

        prompt = f"""
        Translate the following text into {target_lang}.

        Keep the warm, natural, conversational tone.

        Return ONLY the translation.

        Text:
        {text}
        """

        response = self._generate_content(
            prompt,
            temperature=0.4
        )

        if "ERROR" in response:
            return text

        return response.strip()