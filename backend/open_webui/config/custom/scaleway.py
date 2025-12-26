"""
Scaleway Generative AI Configuration
"""
import os
from typing import List, Optional


class ScalewayConfig:
    """Configuration for Scaleway Generative AI endpoints"""

    def __init__(self):
        self.api_base = os.getenv(
            "SCALEWAY_API_BASE",
            "https://api.scaleway.ai/v1"
        )
        self.api_key = os.getenv("SCALEWAY_API_KEY", os.getenv("SCW_SECRET_KEY", ""))
        self.project_id = os.getenv("SCALEWAY_PROJECT_ID", "")

        # Use project-specific endpoint if provided
        if self.project_id:
            self.api_base = f"https://api.scaleway.ai/{self.project_id}/v1"

    @property
    def available_models(self) -> List[str]:
        """List of Scaleway Gen AI models"""
        return [
            "gpt-oss-120b",
        ]

    @property
    def default_model(self) -> str:
        return os.getenv("SCALEWAY_DEFAULT_MODEL", "gpt-oss-120b")

    @property
    def embedding_model(self) -> str:
        return os.getenv(
            "SCALEWAY_EMBEDDING_MODEL",
            "sentence-transformers-multilingual-e5-base"
        )

    def get_connection_info(self) -> dict:
        """Get connection information for Scaleway Gen AI"""
        return {
            "api_base": self.api_base,
            "api_key": self.api_key,
            "default_model": self.default_model,
            "embedding_model": self.embedding_model,
        }


# Global instance
scaleway_config = ScalewayConfig()
