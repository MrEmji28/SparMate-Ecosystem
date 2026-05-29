"""
Pydantic models for the SparMate BKT Microservice.

These models enforce type safety on the data flowing between
the Laravel gateway and the FastAPI BKT engine.
"""

from pydantic import BaseModel, Field
from typing import Optional


# ── Request Models ────────────────────────────────────────────────────────

class ClassifiedBlunder(BaseModel):
    """A single mistake classified by the ML pipeline."""
    category: str = Field(..., description="BKT skill category, e.g. 'tactical_oversight'")
    move: int = Field(..., description="Move number where the blunder occurred")
    severity: str = Field("mistake", description="Severity: 'blunder', 'mistake', or 'inaccuracy'")


class UpdateMasteryRequest(BaseModel):
    """Request payload from Laravel to update a user's BKT matrix."""
    user_id: int
    current_matrix: dict[str, float] = Field(
        ...,
        description="Current BKT mastery probabilities per skill"
    )
    classified_blunders: list[ClassifiedBlunder] = Field(
        default_factory=list,
        description="List of classified blunders from the match"
    )


class GeneratePlanRequest(BaseModel):
    """Request payload to generate a training plan from a BKT matrix."""
    user_id: int
    bkt_matrix: dict[str, float]
    elo_rating: int = 1200


# ── Response Models ───────────────────────────────────────────────────────

class UpdateMasteryResponse(BaseModel):
    """Response containing the updated BKT matrix."""
    status: str = "success"
    user_id: int
    new_matrix: dict[str, float]
    skills_updated: list[str] = Field(default_factory=list)


class PlanItem(BaseModel):
    """A single item in the weekly training plan."""
    day: str
    activity: str
    duration_min: int
    type: str  # 'lesson', 'puzzle', 'sparring'


class GeneratePlanResponse(BaseModel):
    """Response containing the generated training plan."""
    status: str = "success"
    user_id: int
    primary_directive: str
    weekly_focus: list[str]
    plan_items: list[PlanItem]


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "online"
    service: str = "SparMate BKT Microservice"
    version: str = "1.0.0"
