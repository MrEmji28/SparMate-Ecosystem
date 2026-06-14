"""
SparMate Blunder Classifier — Prediction Module

Loads the trained Random Forest or ONNX model and classifies chess
mistakes into the 8 BKT skill categories. This module is used by the
FastAPI microservice to classify blunders from completed matches.

Architecture:
    1. Receives raw move-level data from the Flutter app (via Laravel)
    2. Extracts features using feature_engineering.py
    3. Runs inference through the trained model
    4. Returns classified blunders with categories and severities
    5. These classifications feed into the BKT engine for mastery updates

Usage:
    from classifier import BlunderClassifier

    classifier = BlunderClassifier()
    results = classifier.classify_match(move_analyses)
"""

import os
import json
import numpy as np
from typing import Optional

from feature_engineering import (
    extract_features,
    features_to_array,
    FEATURE_NAMES,
    NUM_FEATURES,
)
from data_generator import CATEGORIES, INDEX_TO_CATEGORY

# ── Constants ────────────────────────────────────────────────────────────

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
RF_MODEL_PATH = os.path.join(MODELS_DIR, "blunder_classifier_rf.joblib")
ONNX_MODEL_PATH = os.path.join(MODELS_DIR, "blunder_classifier_rf.onnx")

# Severity thresholds (centipawn loss)
SEVERITY_THRESHOLDS = {
    "blunder":    200,  # CP loss >= 200 → blunder
    "mistake":    100,  # CP loss >= 100 → mistake
    "inaccuracy":  50,  # CP loss >= 50  → inaccuracy
}


# ── Classifier ───────────────────────────────────────────────────────────

class BlunderClassifier:
    """
    Loads and runs the blunder classification model.

    Supports two backends:
    1. ONNX Runtime (preferred for production / mobile edge deployment)
    2. Joblib / Scikit-Learn (fallback for development)

    If neither model file exists, falls back to a rule-based heuristic
    classifier for graceful degradation.
    """

    def __init__(self, prefer_onnx: bool = True):
        self._model = None
        self._onnx_session = None
        self._backend = "heuristic"

        if prefer_onnx:
            self._try_load_onnx()

        if self._backend == "heuristic":
            self._try_load_sklearn()

        if self._backend == "heuristic":
            print("[Classifier] No trained model found. Using heuristic fallback.")

    def _try_load_onnx(self):
        """Try to load the ONNX model for inference."""
        if not os.path.exists(ONNX_MODEL_PATH):
            return

        try:
            import onnxruntime as ort
            self._onnx_session = ort.InferenceSession(ONNX_MODEL_PATH)
            self._backend = "onnx"
            print(f"[Classifier] Loaded ONNX model: {ONNX_MODEL_PATH}")
        except ImportError:
            print("[Classifier] onnxruntime not installed.")
        except Exception as e:
            print(f"[Classifier] ONNX load failed: {e}")

    def _try_load_sklearn(self):
        """Try to load the Scikit-Learn model for inference."""
        if not os.path.exists(RF_MODEL_PATH):
            return

        try:
            import joblib
            self._model = joblib.load(RF_MODEL_PATH)
            self._backend = "sklearn"
            print(f"[Classifier] Loaded sklearn model: {RF_MODEL_PATH}")
        except ImportError:
            print("[Classifier] joblib not installed.")
        except Exception as e:
            print(f"[Classifier] sklearn load failed: {e}")

    @property
    def backend(self) -> str:
        """Return the active inference backend."""
        return self._backend

    def predict(self, features: list[float]) -> tuple[str, float]:
        """
        Classify a single blunder from its feature vector.

        Args:
            features: Feature vector (list of NUM_FEATURES floats)

        Returns:
            Tuple of (category_name, confidence)
        """
        X = np.array([features], dtype=np.float32)

        if self._backend == "onnx":
            return self._predict_onnx(X)
        elif self._backend == "sklearn":
            return self._predict_sklearn(X)
        else:
            return self._predict_heuristic(features)

    def _predict_onnx(self, X: np.ndarray) -> tuple[str, float]:
        """Run inference through the ONNX model."""
        input_name = self._onnx_session.get_inputs()[0].name
        results = self._onnx_session.run(None, {input_name: X})

        predicted_class = int(results[0][0])
        category = INDEX_TO_CATEGORY.get(predicted_class, "tactical_oversight")

        # Try to get probability
        confidence = 0.85
        if len(results) > 1:
            probabilities = results[1][0]
            if isinstance(probabilities, np.ndarray):
                confidence = float(probabilities.max())
            elif isinstance(probabilities, dict):
                confidence = max(probabilities.values())

        return category, confidence

    def _predict_sklearn(self, X: np.ndarray) -> tuple[str, float]:
        """Run inference through the Scikit-Learn model."""
        predicted_class = int(self._model.predict(X)[0])
        category = INDEX_TO_CATEGORY.get(predicted_class, "tactical_oversight")

        confidence = 0.85
        if hasattr(self._model, "predict_proba"):
            probas = self._model.predict_proba(X)[0]
            confidence = float(probas.max())

        return category, confidence

    def _predict_heuristic(self, features: list[float]) -> tuple[str, float]:
        """
        Rule-based fallback classifier when no trained model is available.

        Uses the key distinguishing features identified during feature
        engineering to make a reasonable classification.
        """
        # Extract key features by index
        cp_loss = features[0]           # cp_loss
        is_opening = features[10]       # is_opening
        is_endgame = features[12]       # is_endgame
        pieces_en_prise = features[17]  # pieces_en_prise
        hanging_value = features[18]    # hanging_material_value
        capture_available = features[19]  # capture_available
        own_king_exposure = features[22]  # own_king_exposure
        pawn_shield = features[24]      # own_king_pawn_shield
        doubled = features[26]          # doubled_pawns
        isolated = features[27]         # isolated_pawns
        pawn_change = features[30]      # pawn_structure_change
        mobility = features[31]         # piece_mobility
        developed = features[32]        # pieces_developed
        time_remaining = features[35]   # time_remaining_pct
        time_pressure = features[36]    # time_pressure

        # Rule-based classification
        if time_pressure > 0.5 and time_remaining < 0.1:
            return "time_management", 0.70
        elif is_opening > 0.5 and developed < 0.4:
            return "opening_theory", 0.70
        elif is_endgame > 0.5:
            return "endgame_fundamentals", 0.65
        elif own_king_exposure > 0.6 and pawn_shield < 0.4:
            return "king_safety", 0.70
        elif pawn_change > 0.5 and (doubled > 1.5 or isolated > 1.5):
            return "pawn_structure", 0.65
        elif pieces_en_prise > 2 and hanging_value > 3 and capture_available > 0.5:
            return "tactical_oversight", 0.75
        elif mobility < 0.25 and developed < 0.5:
            return "piece_coordination", 0.60
        elif cp_loss > 100 and capture_available > 0.5:
            return "tactical_oversight", 0.65
        else:
            return "positional_error", 0.55

    def classify_move(
        self,
        eval_before: float,
        eval_after: float,
        move_number: int,
        **kwargs,
    ) -> Optional[dict]:
        """
        Classify a single move. Returns None if the move is not a mistake.

        Args:
            eval_before: Engine eval (centipawns) before the move
            eval_after:  Engine eval (centipawns) after the move
            move_number: Move number in the game
            **kwargs:    Additional features (see feature_engineering.extract_features)

        Returns:
            Dict with 'category', 'severity', 'move', 'confidence'
            or None if CP loss is below inaccuracy threshold.
        """
        cp_loss = eval_before - eval_after

        # Skip good moves and minor inaccuracies
        if cp_loss < SEVERITY_THRESHOLDS["inaccuracy"]:
            return None

        # Determine severity
        if cp_loss >= SEVERITY_THRESHOLDS["blunder"]:
            severity = "blunder"
        elif cp_loss >= SEVERITY_THRESHOLDS["mistake"]:
            severity = "mistake"
        else:
            severity = "inaccuracy"

        # Extract features
        features_dict = extract_features(
            eval_before=eval_before,
            eval_after=eval_after,
            move_number=move_number,
            **kwargs,
        )
        features_array = features_to_array(features_dict)

        # Classify
        category, confidence = self.predict(features_array)

        return {
            "category": category,
            "severity": severity,
            "move": move_number,
            "confidence": round(confidence, 3),
            "cp_loss": round(cp_loss, 1),
        }

    def classify_match(self, move_analyses: list[dict]) -> list[dict]:
        """
        Classify all moves in a completed match.

        Args:
            move_analyses: List of dicts, each containing:
                - eval_before: float (centipawns)
                - eval_after: float (centipawns)
                - move_number: int
                - (optional) additional features

        Returns:
            List of classified blunders (only moves that are mistakes/blunders)
        """
        classified = []

        for move_data in move_analyses:
            result = self.classify_move(
                eval_before=move_data.get("eval_before", 0),
                eval_after=move_data.get("eval_after", 0),
                move_number=move_data.get("move_number", 1),
                total_pieces=move_data.get("total_pieces", 24),
                has_queens=move_data.get("has_queens", True),
                pieces_en_prise=move_data.get("pieces_en_prise", 0),
                hanging_value=move_data.get("hanging_value", 0),
                capture_available=move_data.get("capture_available", False),
                check_available=move_data.get("check_available", False),
                own_king_exposure=move_data.get("own_king_exposure", 0.0),
                own_king_pawn_shield=move_data.get("own_king_pawn_shield", 3),
                king_has_castled=move_data.get("king_has_castled", True),
                doubled_pawns=move_data.get("doubled_pawns", 0),
                isolated_pawns=move_data.get("isolated_pawns", 0),
                passed_pawns=move_data.get("passed_pawns", 0),
                pawn_structure_changed=move_data.get("pawn_structure_changed", False),
                piece_mobility=move_data.get("piece_mobility", 0.5),
                pieces_developed=move_data.get("pieces_developed", 6),
                time_remaining_pct=move_data.get("time_remaining_pct", 0.75),
                time_pressure=move_data.get("time_pressure", False),
            )

            if result is not None:
                classified.append(result)

        return classified


# ── Module-level singleton ───────────────────────────────────────────────

_classifier_instance: Optional[BlunderClassifier] = None


def get_classifier() -> BlunderClassifier:
    """Get or create the singleton classifier instance."""
    global _classifier_instance
    if _classifier_instance is None:
        _classifier_instance = BlunderClassifier()
    return _classifier_instance
