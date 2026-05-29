"""
SparMate BKT Microservice — FastAPI Application

This microservice handles the heavy mathematical logic for Bayesian
Knowledge Tracing, keeping the Laravel gateway fast. It processes
classified blunders from sparring matches and generates personalized
training plans.

Architecture (from Milestone 2):
    Flutter App → Laravel Gateway → FastAPI BKT Microservice → PostgreSQL

Endpoints:
    POST /api/v1/update-mastery  — Update BKT matrix after a match
    POST /api/v1/generate-plan   — Generate a training plan from BKT data
    GET  /health                 — Health check
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from models import (
    UpdateMasteryRequest,
    UpdateMasteryResponse,
    GeneratePlanRequest,
    GeneratePlanResponse,
    HealthResponse,
    PlanItem,
)
from bkt_engine import process_match_blunders, generate_training_plan

# ── App Configuration ─────────────────────────────────────────────────────

app = FastAPI(
    title="SparMate BKT Microservice",
    description="Bayesian Knowledge Tracing engine for adaptive chess coaching.",
    version="1.0.0",
)

# Allow Laravel to communicate from any origin during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health Check ──────────────────────────────────────────────────────────

@app.get("/", response_model=HealthResponse)
@app.get("/health", response_model=HealthResponse)
def health_check():
    """Basic health check endpoint."""
    return HealthResponse()


# ── BKT Mastery Update ───────────────────────────────────────────────────

@app.post("/api/v1/update-mastery", response_model=UpdateMasteryResponse)
async def update_mastery(payload: UpdateMasteryRequest):
    """
    Update a user's BKT mastery matrix after a completed sparring match.

    Receives the current matrix and a list of classified blunders,
    applies Bayesian posterior updates for each blunder, then applies
    learning transitions. Returns the updated matrix.

    This implements the algorithm from Milestone 2, Section 4.5:
        P(mastered | incorrect) = P(slip) * P(mastered) /
            [P(slip) * P(mastered) + (1 - P(guess)) * (1 - P(mastered))]
    """
    if not payload.current_matrix:
        raise HTTPException(status_code=400, detail="current_matrix is required")

    # Convert Pydantic models to dicts for the engine
    blunders = [b.model_dump() for b in payload.classified_blunders]

    # Process through BKT engine
    new_matrix, skills_updated = process_match_blunders(
        current_matrix=payload.current_matrix,
        classified_blunders=blunders,
    )

    return UpdateMasteryResponse(
        user_id=payload.user_id,
        new_matrix=new_matrix,
        skills_updated=skills_updated,
    )


# ── Training Plan Generation ─────────────────────────────────────────────

@app.post("/api/v1/generate-plan", response_model=GeneratePlanResponse)
async def create_training_plan(payload: GeneratePlanRequest):
    """
    Generate a personalized weekly training plan based on the user's
    BKT mastery matrix.

    Strategy:
    1. Identify the 3 weakest cognitive skills
    2. Map each to targeted activities (lessons, puzzles, sparring)
    3. Build a 7-day weekly plan
    """
    if not payload.bkt_matrix:
        raise HTTPException(status_code=400, detail="bkt_matrix is required")

    plan_data = generate_training_plan(
        bkt_matrix=payload.bkt_matrix,
        elo_rating=payload.elo_rating,
    )

    return GeneratePlanResponse(
        user_id=payload.user_id,
        primary_directive=plan_data["primary_directive"],
        weekly_focus=plan_data["weekly_focus"],
        plan_items=[PlanItem(**item) for item in plan_data["plan_items"]],
    )


# ── Run with: uvicorn main:app --reload --port 8000 ──────────────────────