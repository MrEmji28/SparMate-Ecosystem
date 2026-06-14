"""
Pydantic models for the SparMate ML Microservice.

These models enforce type safety on the data flowing between
the Laravel gateway and the FastAPI engine. Covers both the
BKT mastery tracking (Sprint 4) and blunder classification (Sprint 5-6).
"""

from pydantic import BaseModel, Field
from typing import Optional


# ── BKT Request Models ───────────────────────────────────────────────────

class ClassifiedBlunder(BaseModel):
    """A single mistake classified by the ML pipeline."""
    category: str = Field(..., description="BKT skill category, e.g. 'tactical_oversight'")
    move: int = Field(..., description="Move number where the blunder occurred")
    severity: str = Field("mistake", description="Severity: 'blunder', 'mistake', or 'inaccuracy'")
    confidence: float = Field(0.0, description="Classification confidence (0-1)")
    cp_loss: float = Field(0.0, description="Centipawn loss for this move")


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


# ── Classification Request Models ────────────────────────────────────────

class MoveAnalysis(BaseModel):
    """
    Raw move-level data from the Stockfish engine analysis.
    Sent from Flutter → Laravel → FastAPI for classification.
    """
    eval_before: float = Field(..., description="Engine eval (centipawns) before the move")
    eval_after: float = Field(..., description="Engine eval (centipawns) after the move")
    move_number: int = Field(..., description="Move number in the game")
    total_pieces: int = Field(24, description="Total pieces on the board")
    has_queens: bool = Field(True, description="Whether both queens are on the board")
    pieces_en_prise: int = Field(0, description="Number of undefended pieces")
    hanging_value: int = Field(0, description="Value of hanging pieces (centipawns)")
    capture_available: bool = Field(False, description="Whether a capture was available")
    check_available: bool = Field(False, description="Whether a check was available")
    own_king_exposure: float = Field(0.0, description="King exposure score (0-1)")
    own_king_pawn_shield: int = Field(3, description="Pawn shield quality (0-3)")
    king_has_castled: bool = Field(True, description="Whether the player has castled")
    doubled_pawns: int = Field(0, description="Number of doubled pawns")
    isolated_pawns: int = Field(0, description="Number of isolated pawns")
    passed_pawns: int = Field(0, description="Number of passed pawns")
    pawn_structure_changed: bool = Field(False, description="If pawn structure changed")
    piece_mobility: float = Field(0.5, description="Piece mobility score (0-1)")
    pieces_developed: int = Field(6, description="Number of developed pieces (0-8)")
    time_remaining_pct: float = Field(0.75, description="Clock remaining (0-1)")
    time_pressure: bool = Field(False, description="Whether under severe time pressure")


class ClassifyMatchRequest(BaseModel):
    """Request payload to classify all mistakes in a completed match."""
    user_id: int
    match_id: int = Field(0, description="Match ID from the Laravel database")
    move_analyses: list[MoveAnalysis] = Field(
        ...,
        description="List of move-level analysis data from the engine"
    )


class ClassifyMatchResponse(BaseModel):
    """Response containing classified blunders from the match."""
    status: str = "success"
    user_id: int
    match_id: int = 0
    classified_blunders: list[ClassifiedBlunder] = Field(default_factory=list)
    total_moves_analyzed: int = 0
    blunders_found: int = 0
    classifier_backend: str = "heuristic"


# ── BKT Response Models ─────────────────────────────────────────────────

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
    service: str = "SparMate ML Microservice"
    version: str = "2.0.0"

