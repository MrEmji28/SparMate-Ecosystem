"""
SparMate ML Microservice — FastAPI Application

This microservice handles:
1. Blunder Classification (Sprint 5-6): Classifies chess mistakes into
   8 cognitive skill categories using a Random Forest / ONNX model.
2. Bayesian Knowledge Tracing (Sprint 4): Tracks student mastery of
   chess skills using Corbett & Anderson (1995) methodology.
3. Training Plan Generation: Creates personalized weekly training plans.

Architecture (from Milestone 2):
    Flutter App → Laravel Gateway → FastAPI ML Microservice → PostgreSQL

Endpoints:
    POST /api/v1/classify-match    — Classify blunders in a completed match
    POST /api/v1/update-mastery    — Update BKT matrix after a match
    POST /api/v1/generate-plan     — Generate a training plan from BKT data
    GET  /health                   — Health check
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from models import (
    UpdateMasteryRequest,
    UpdateMasteryResponse,
    GeneratePlanRequest,
    GeneratePlanResponse,
    ClassifyMatchRequest,
    ClassifyMatchResponse,
    ClassifiedBlunder,
    HealthResponse,
    PlanItem,
    CoachingInsightsRequest,
    CoachingInsightsResponse,
    CoachingIndicator,
    EloForecastRequest,
    EloForecastResponse,
)
from bkt_engine import process_match_blunders, generate_training_plan, generate_coaching_insights
from classifier import get_classifier

# ── App Configuration ─────────────────────────────────────────────────────

app = FastAPI(
    title="SparMate ML Microservice",
    description=(
        "Blunder classification and Bayesian Knowledge Tracing engine "
        "for adaptive chess coaching."
    ),
    version="2.0.0",
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
    classifier = get_classifier()
    return HealthResponse(
        status="online",
        service=f"SparMate ML Microservice (classifier: {classifier.backend})",
    )


# ── Blunder Classification (Sprint 5-6) ─────────────────────────────────

@app.post("/api/v1/classify-match", response_model=ClassifyMatchResponse)
async def classify_match(payload: ClassifyMatchRequest):
    """
    Classify all mistakes in a completed sparring match.

    Receives move-level analysis data from the Stockfish engine (via Laravel)
    and classifies each mistake into one of 8 BKT cognitive skill categories.

    This implements the ML pipeline from Milestone 2, Section 4.4:
    1. Extract features from pre/post-blunder positions
    2. Run inference through the trained Random Forest / ONNX model
    3. Return classified blunders with categories and severities

    The classifications are then fed into the BKT engine to update
    the user's mastery matrix.
    """
    if not payload.move_analyses:
        raise HTTPException(status_code=400, detail="move_analyses is required")

    classifier = get_classifier()

    # Convert Pydantic models to dicts for the classifier
    move_dicts = [m.model_dump() for m in payload.move_analyses]

    # Classify
    classified = classifier.classify_match(move_dicts)

    # Convert to response models
    blunders = [
        ClassifiedBlunder(
            category=b["category"],
            move=b["move"],
            severity=b["severity"],
            confidence=b.get("confidence", 0.0),
            cp_loss=b.get("cp_loss", 0.0),
        )
        for b in classified
    ]

    return ClassifyMatchResponse(
        user_id=payload.user_id,
        match_id=payload.match_id,
        classified_blunders=blunders,
        total_moves_analyzed=len(payload.move_analyses),
        blunders_found=len(blunders),
        classifier_backend=classifier.backend,
    )


# ── BKT Mastery Update (Sprint 4) ───────────────────────────────────────

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
        skill_level=payload.skill_level,
    )

    return GeneratePlanResponse(
        user_id=payload.user_id,
        primary_directive=plan_data["primary_directive"],
        weekly_focus=plan_data["weekly_focus"],
        plan_items=[PlanItem(**item) for item in plan_data["plan_items"]],
    )


# ── Coaching Insights (Sprint 6+) ────────────────────────────────────────

@app.post("/api/v1/coaching-insights", response_model=CoachingInsightsResponse)
async def coaching_insights(payload: CoachingInsightsRequest):
    """
    Generate coaching indicators from recent match blunders.

    Analyzes the user's recent classified blunders and generates
    human-readable coaching feedback for the Coaching Engine UI.
    Each match produces 1-2 indicators highlighting specific areas
    for improvement or praising clean play.
    """
    # Convert Pydantic models to dicts
    matches = []
    for match in payload.recent_matches:
        matches.append({
            "match_id": match.match_id,
            "opponent_name": match.opponent_name,
            "result": match.result,
            "blunders": [b.model_dump() for b in match.blunders],
        })

    insights = generate_coaching_insights(
        recent_matches=matches,
        bkt_matrix=payload.bkt_matrix,
    )

    return CoachingInsightsResponse(
        user_id=payload.user_id,
        recent_indicators=[
            CoachingIndicator(**ind) for ind in insights["recent_indicators"]
        ],
        skill_trends=insights["skill_trends"],
    )


# ── ELO Trend Prediction — Linear Regression (Sprint 10) ────────────────

@app.post("/api/v1/predict-elo", response_model=EloForecastResponse)
async def predict_elo(payload: EloForecastRequest):
    """
    Predict a player's future ELO rating using Linear Regression.

    Algorithm:
    1. Map each historical ELO value to a sequential index (x = match number)
    2. Fit sklearn LinearRegression on (x, elo) pairs
    3. Compute R² score as goodness-of-fit metric
    4. Extrapolate to (n + horizon_days) future time steps
    5. Estimate confidence interval using residual standard deviation

    This provides:
    - A 14-day ELO forecast line (dashed continuation of the history chart)
    - A confidence band (±1 std dev of residuals)
    - Trend direction: improving / stable / declining
    - Slope: ELO change per match (interpretable unit for the UI)
    """
    import numpy as np
    from sklearn.linear_model import LinearRegression
    from sklearn.metrics import r2_score

    history = payload.elo_history
    n = len(history)

    # ── Fit Linear Regression ────────────────────────────────────────────
    X = np.arange(n).reshape(-1, 1)          # [0, 1, 2, ... n-1]
    y = np.array(history, dtype=float)        # ELO values

    model = LinearRegression()
    model.fit(X, y)

    y_pred_hist = model.predict(X)
    residuals = y - y_pred_hist
    residual_std = float(np.std(residuals)) if len(residuals) > 1 else 30.0

    r2 = float(r2_score(y, y_pred_hist))
    slope = float(model.coef_[0])             # ELO change per match

    # ── Forecast future steps ─────────────────────────────────────────────
    future_X = np.arange(n, n + payload.horizon_days).reshape(-1, 1)
    future_pred = model.predict(future_X)

    # Anchor the first forecast point to the real current ELO
    # to avoid a visual jump between history and forecast lines.
    anchor_delta = payload.current_elo - float(future_pred[0])
    future_pred = future_pred + anchor_delta

    predicted = [max(800, int(round(v))) for v in future_pred]
    lower     = [max(800, int(round(v - residual_std))) for v in future_pred]
    upper     = [max(800, int(round(v + residual_std))) for v in future_pred]

    # ── Trend classification ──────────────────────────────────────────────
    # Use slope magnitude relative to rating scale; ±1.5 ELO/match = stable
    if slope > 1.5:
        trend = "improving"
    elif slope < -1.5:
        trend = "declining"
    else:
        trend = "stable"

    return EloForecastResponse(
        user_id=payload.user_id,
        predicted_ratings=predicted,
        lower_bound=lower,
        upper_bound=upper,
        trend=trend,
        projected_elo=predicted[-1],
        r2_score=round(r2, 4),
        slope=round(slope, 2),
    )


# ── Run with: uvicorn main:app --reload --port 8000 ──────────────────────