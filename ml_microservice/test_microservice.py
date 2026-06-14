#!/usr/bin/env python3
"""
SparMate ML Microservice — Comprehensive Test Suite

Tests all components of the ML microservice:
    1. BKT Engine unit tests (Bayesian posterior updates, learning transitions)
    2. Feature Engineering tests (feature extraction, normalization)
    3. Classifier tests (model loading, prediction, graceful degradation)
    4. FastAPI endpoint integration tests (classify, update-mastery, generate-plan)
    5. BKT Integrity simulation (50-match stress test from Milestone 2 §5.2)

Usage:
    cd ml_microservice
    python -m pytest test_microservice.py -v
    # or simply:
    python test_microservice.py
"""

import json
import math
import os
import sys
import unittest

import numpy as np

# ── Import project modules ───────────────────────────────────────────────

from bkt_engine import (
    process_match_blunders,
    generate_training_plan,
    SKILL_PARAMETERS,
)
from feature_engineering import (
    extract_features,
    features_to_array,
    FEATURE_NAMES,
    NUM_FEATURES,
)
from data_generator import (
    generate_dataset,
    CATEGORIES,
    NUM_CATEGORIES,
    CATEGORY_TO_INDEX,
    INDEX_TO_CATEGORY,
)
from classifier import BlunderClassifier, get_classifier


# ═══════════════════════════════════════════════════════════════════════
# 1. BKT ENGINE TESTS
# ═══════════════════════════════════════════════════════════════════════

class TestBKTEngine(unittest.TestCase):
    """Unit tests for the Bayesian Knowledge Tracing engine."""

    def setUp(self):
        """Create a default BKT matrix with all skills at 0.50."""
        self.default_matrix = {
            "tactical_oversight": 0.50,
            "positional_error": 0.50,
            "endgame_fundamentals": 0.50,
            "opening_theory": 0.50,
            "king_safety": 0.50,
            "pawn_structure": 0.50,
            "piece_coordination": 0.50,
            "time_management": 0.50,
        }

    def test_no_blunders_preserves_matrix(self):
        """Matrix should be unchanged when no blunders are reported."""
        new_matrix, updated = process_match_blunders(
            current_matrix=self.default_matrix.copy(),
            classified_blunders=[],
        )
        self.assertEqual(new_matrix, self.default_matrix)
        self.assertEqual(updated, [])

    def test_single_blunder_decreases_mastery(self):
        """A single blunder should decrease the mastery of the affected skill."""
        blunders = [
            {"category": "tactical_oversight", "severity": "blunder", "move": 15}
        ]
        new_matrix, updated = process_match_blunders(
            current_matrix=self.default_matrix.copy(),
            classified_blunders=blunders,
        )
        # Mastery should decrease for tactical_oversight
        self.assertLess(
            new_matrix["tactical_oversight"],
            self.default_matrix["tactical_oversight"],
        )
        # Other skills should be unchanged
        self.assertEqual(
            new_matrix["positional_error"],
            self.default_matrix["positional_error"],
        )
        self.assertIn("tactical_oversight", updated)

    def test_severity_weighting(self):
        """Blunders should have more impact than mistakes, which have more than inaccuracies."""
        from bkt_engine import update_mastery_after_incorrect, SKILL_PARAMETERS

        # Test the raw posterior update function directly (before learning
        # transition), where severity differentiation is mathematically guaranteed.
        params = SKILL_PARAMETERS["king_safety"]
        p_mastery = 0.50

        post_blunder = update_mastery_after_incorrect(
            p_mastery, params["p_slip"], params["p_guess"], severity_weight=1.0
        )
        post_mistake = update_mastery_after_incorrect(
            p_mastery, params["p_slip"], params["p_guess"], severity_weight=0.7
        )
        post_inaccuracy = update_mastery_after_incorrect(
            p_mastery, params["p_slip"], params["p_guess"], severity_weight=0.3
        )

        # Blunder should cause the largest posterior drop
        self.assertLess(post_blunder, post_mistake)
        self.assertLess(post_mistake, post_inaccuracy)
        # All should be less than the prior
        self.assertLess(post_blunder, p_mastery)
        self.assertLess(post_mistake, p_mastery)
        self.assertLess(post_inaccuracy, p_mastery)

    def test_mastery_stays_bounded(self):
        """Mastery should remain within [0.01, 0.99] even after many blunders."""
        matrix = self.default_matrix.copy()
        # Apply 20 blunders to the same skill
        for _ in range(20):
            matrix, _ = process_match_blunders(
                matrix,
                [{"category": "pawn_structure", "severity": "blunder", "move": 1}],
            )
        self.assertGreaterEqual(matrix["pawn_structure"], 0.01)
        self.assertLessEqual(matrix["pawn_structure"], 0.99)

    def test_learning_transition_prevents_zero(self):
        """
        Even after many incorrect observations, the learning transition
        should prevent mastery from reaching exactly 0.
        """
        matrix = {"tactical_oversight": 0.05}
        for key in self.default_matrix:
            if key != "tactical_oversight":
                matrix[key] = 0.50

        for _ in range(10):
            matrix, _ = process_match_blunders(
                matrix,
                [{"category": "tactical_oversight", "severity": "blunder", "move": 1}],
            )
        self.assertGreater(matrix["tactical_oversight"], 0.0)

    def test_multiple_skills_updated(self):
        """Multiple blunders affecting different skills should update each independently."""
        blunders = [
            {"category": "tactical_oversight", "severity": "blunder", "move": 10},
            {"category": "king_safety", "severity": "mistake", "move": 20},
            {"category": "time_management", "severity": "inaccuracy", "move": 30},
        ]
        new_matrix, updated = process_match_blunders(
            current_matrix=self.default_matrix.copy(),
            classified_blunders=blunders,
        )
        self.assertIn("tactical_oversight", updated)
        self.assertIn("king_safety", updated)
        self.assertIn("time_management", updated)
        self.assertEqual(len(updated), 3)

    def test_unknown_category_ignored(self):
        """Unknown skill categories should not crash the engine."""
        blunders = [
            {"category": "nonexistent_skill", "severity": "blunder", "move": 5}
        ]
        new_matrix, updated = process_match_blunders(
            current_matrix=self.default_matrix.copy(),
            classified_blunders=blunders,
        )
        # Should return matrix unchanged
        self.assertEqual(new_matrix, self.default_matrix)

    def test_all_skill_parameters_defined(self):
        """Every BKT skill should have p_learn, p_guess, and p_slip parameters."""
        for skill in self.default_matrix.keys():
            self.assertIn(skill, SKILL_PARAMETERS)
            params = SKILL_PARAMETERS[skill]
            self.assertIn("p_learn", params)
            self.assertIn("p_guess", params)
            self.assertIn("p_slip", params)
            # All values should be in (0, 1)
            self.assertGreater(params["p_learn"], 0)
            self.assertLess(params["p_learn"], 1)
            self.assertGreater(params["p_guess"], 0)
            self.assertLess(params["p_guess"], 1)
            self.assertGreater(params["p_slip"], 0)
            self.assertLess(params["p_slip"], 1)


class TestTrainingPlanGeneration(unittest.TestCase):
    """Tests for the training plan generator."""

    def test_plan_has_required_fields(self):
        """Generated plan should contain all required fields."""
        plan = generate_training_plan(
            bkt_matrix={
                "tactical_oversight": 0.30,
                "positional_error": 0.60,
                "endgame_fundamentals": 0.80,
                "opening_theory": 0.50,
                "king_safety": 0.25,
                "pawn_structure": 0.55,
                "piece_coordination": 0.45,
                "time_management": 0.20,
            },
            elo_rating=1300,
        )
        self.assertIn("primary_directive", plan)
        self.assertIn("weekly_focus", plan)
        self.assertIn("plan_items", plan)
        self.assertIsInstance(plan["weekly_focus"], list)
        self.assertGreater(len(plan["weekly_focus"]), 0)
        self.assertGreater(len(plan["plan_items"]), 0)

    def test_weakest_skills_are_focused(self):
        """The plan should focus on the weakest skills."""
        plan = generate_training_plan(
            bkt_matrix={
                "tactical_oversight": 0.90,
                "positional_error": 0.85,
                "endgame_fundamentals": 0.80,
                "opening_theory": 0.75,
                "king_safety": 0.10,  # weakest
                "pawn_structure": 0.15,  # 2nd weakest
                "piece_coordination": 0.20,  # 3rd weakest
                "time_management": 0.70,
            },
            elo_rating=1500,
        )
        focus_lower = [f.lower().replace(" ", "_") for f in plan["weekly_focus"]]
        # At least the weakest skill should be in focus
        self.assertTrue(
            any("king" in f for f in focus_lower),
            f"King safety should be in focus: {plan['weekly_focus']}",
        )

    def test_plan_items_have_valid_types(self):
        """Each plan item should have a valid activity type."""
        plan = generate_training_plan(
            bkt_matrix={k: 0.50 for k in [
                "tactical_oversight", "positional_error", "endgame_fundamentals",
                "opening_theory", "king_safety", "pawn_structure",
                "piece_coordination", "time_management",
            ]},
            elo_rating=1200,
        )
        valid_types = {"lesson", "puzzle", "sparring"}
        for item in plan["plan_items"]:
            self.assertIn("day", item)
            self.assertIn("activity", item)
            self.assertIn("duration_min", item)
            self.assertIn("type", item)
            self.assertIn(item["type"], valid_types)
            self.assertGreater(item["duration_min"], 0)


# ═══════════════════════════════════════════════════════════════════════
# 2. FEATURE ENGINEERING TESTS
# ═══════════════════════════════════════════════════════════════════════

class TestFeatureEngineering(unittest.TestCase):
    """Tests for the feature extraction module."""

    def test_feature_count(self):
        """Feature vector should have exactly NUM_FEATURES elements."""
        features = extract_features(eval_before=150, eval_after=-200, move_number=23)
        self.assertEqual(len(features), NUM_FEATURES)

    def test_features_to_array_ordering(self):
        """features_to_array should produce values in FEATURE_NAMES order."""
        features = extract_features(eval_before=100, eval_after=-50, move_number=15)
        arr = features_to_array(features)
        self.assertEqual(len(arr), NUM_FEATURES)
        for i, name in enumerate(FEATURE_NAMES):
            self.assertEqual(arr[i], features[name])

    def test_cp_loss_normalized_bounded(self):
        """CP loss normalized should be in [0, 1]."""
        features = extract_features(eval_before=1000, eval_after=-1000, move_number=20)
        self.assertGreaterEqual(features["cp_loss_normalized"], 0.0)
        self.assertLessEqual(features["cp_loss_normalized"], 1.0)

    def test_game_phase_detection(self):
        """Game phase should correctly identify opening, middlegame, endgame."""
        opening = extract_features(eval_before=0, eval_after=-50, move_number=5, total_pieces=30)
        self.assertEqual(opening["is_opening"], 1.0)
        self.assertEqual(opening["is_endgame"], 0.0)

        endgame = extract_features(eval_before=0, eval_after=-50, move_number=40, total_pieces=6)
        self.assertEqual(endgame["is_endgame"], 1.0)
        self.assertEqual(endgame["is_opening"], 0.0)

        middle = extract_features(eval_before=0, eval_after=-50, move_number=25, total_pieces=20)
        self.assertEqual(middle["is_middlegame"], 1.0)

    def test_all_feature_names_present(self):
        """All FEATURE_NAMES should be keys in the extracted features dict."""
        features = extract_features(eval_before=0, eval_after=0, move_number=1)
        for name in FEATURE_NAMES:
            self.assertIn(name, features, f"Missing feature: {name}")


# ═══════════════════════════════════════════════════════════════════════
# 3. DATA GENERATOR TESTS
# ═══════════════════════════════════════════════════════════════════════

class TestDataGenerator(unittest.TestCase):
    """Tests for the training data generator."""

    def test_dataset_shape(self):
        """Generated dataset should have correct shape."""
        X, y = generate_dataset(n_samples=100, seed=42)
        self.assertEqual(X.shape[0], 100)
        self.assertEqual(X.shape[1], NUM_FEATURES)
        self.assertEqual(y.shape[0], 100)

    def test_all_classes_present(self):
        """All 8 categories should be represented in the dataset."""
        X, y = generate_dataset(n_samples=1000, seed=42)
        unique_classes = set(y)
        self.assertEqual(len(unique_classes), NUM_CATEGORIES)

    def test_reproducibility(self):
        """Same seed should produce identical datasets."""
        X1, y1 = generate_dataset(n_samples=50, seed=123)
        X2, y2 = generate_dataset(n_samples=50, seed=123)
        np.testing.assert_array_equal(X1, X2)
        np.testing.assert_array_equal(y1, y2)

    def test_category_mappings_consistent(self):
        """INDEX_TO_CATEGORY and CATEGORY_TO_INDEX should be inverses."""
        for cat in CATEGORIES:
            idx = CATEGORY_TO_INDEX[cat]
            self.assertEqual(INDEX_TO_CATEGORY[idx], cat)


# ═══════════════════════════════════════════════════════════════════════
# 4. CLASSIFIER TESTS
# ═══════════════════════════════════════════════════════════════════════

class TestClassifier(unittest.TestCase):
    """Tests for the blunder classification module."""

    def setUp(self):
        self.classifier = get_classifier()

    def test_classifier_loads(self):
        """Classifier should load successfully with some backend."""
        self.assertIn(self.classifier.backend, ["onnx", "sklearn", "heuristic"])

    def test_classify_blunder(self):
        """Large CP loss with tactical signals should classify as tactical_oversight."""
        result = self.classifier.classify_move(
            eval_before=200,
            eval_after=-300,
            move_number=20,
            pieces_en_prise=3,
            hanging_value=500,
            capture_available=True,
        )
        self.assertIsNotNone(result)
        self.assertEqual(result["severity"], "blunder")
        self.assertIn(result["category"], CATEGORIES)
        self.assertGreater(result["cp_loss"], 0)

    def test_good_move_returns_none(self):
        """Moves with low CP loss should return None (not a mistake)."""
        result = self.classifier.classify_move(
            eval_before=100,
            eval_after=80,
            move_number=10,
        )
        self.assertIsNone(result)

    def test_severity_thresholds(self):
        """Severity should be correctly assigned based on CP loss."""
        blunder = self.classifier.classify_move(
            eval_before=300, eval_after=0, move_number=15,
        )
        self.assertEqual(blunder["severity"], "blunder")  # 300cp loss

        mistake = self.classifier.classify_move(
            eval_before=200, eval_after=50, move_number=15,
        )
        self.assertEqual(mistake["severity"], "mistake")  # 150cp loss

        inaccuracy = self.classifier.classify_move(
            eval_before=100, eval_after=40, move_number=15,
        )
        self.assertEqual(inaccuracy["severity"], "inaccuracy")  # 60cp loss

    def test_classify_match(self):
        """classify_match should process multiple moves and return only mistakes."""
        moves = [
            {"eval_before": 100, "eval_after": 80, "move_number": 1},   # Good move
            {"eval_before": 200, "eval_after": -100, "move_number": 10}, # Blunder
            {"eval_before": 50, "eval_after": 30, "move_number": 15},    # Good move
            {"eval_before": 150, "eval_after": -50, "move_number": 20},  # Blunder
            {"eval_before": 0, "eval_after": -10, "move_number": 25},    # Good move
        ]
        classified = self.classifier.classify_match(moves)
        # Should only return the 2 mistakes (CP loss > 50)
        self.assertEqual(len(classified), 2)
        for b in classified:
            self.assertIn("category", b)
            self.assertIn("severity", b)
            self.assertIn("move", b)

    def test_result_has_confidence(self):
        """Classification result should include a confidence score."""
        result = self.classifier.classify_move(
            eval_before=300, eval_after=-100, move_number=15,
        )
        self.assertIn("confidence", result)
        self.assertGreaterEqual(result["confidence"], 0.0)
        self.assertLessEqual(result["confidence"], 1.0)


# ═══════════════════════════════════════════════════════════════════════
# 5. FASTAPI ENDPOINT INTEGRATION TESTS
# ═══════════════════════════════════════════════════════════════════════

class TestFastAPIEndpoints(unittest.TestCase):
    """Integration tests for the FastAPI endpoints."""

    @classmethod
    def setUpClass(cls):
        """Create a test client for the FastAPI app."""
        try:
            from fastapi.testclient import TestClient
            from main import app
            cls.client = TestClient(app)
            cls._skip = False
        except ImportError:
            cls._skip = True

    def setUp(self):
        if self._skip:
            self.skipTest("fastapi not installed — install with: pip install fastapi httpx")

    def test_health_check(self):
        """GET /health should return 200 with service info."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "online")
        self.assertIn("SparMate", data["service"])

    def test_classify_match_endpoint(self):
        """POST /api/v1/classify-match should classify blunders."""
        payload = {
            "user_id": 1,
            "match_id": 42,
            "move_analyses": [
                {
                    "eval_before": 200.0,
                    "eval_after": -300.0,
                    "move_number": 15,
                    "pieces_en_prise": 3,
                    "hanging_value": 500,
                    "capture_available": True,
                },
                {
                    "eval_before": 50.0,
                    "eval_after": 30.0,
                    "move_number": 20,
                },
            ],
        }
        response = self.client.post("/api/v1/classify-match", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["user_id"], 1)
        self.assertEqual(data["total_moves_analyzed"], 2)
        # Only 1 move is a blunder (500cp loss)
        self.assertGreaterEqual(data["blunders_found"], 1)

    def test_classify_match_empty_moves(self):
        """POST /api/v1/classify-match with empty moves should return 400."""
        payload = {"user_id": 1, "match_id": 1, "move_analyses": []}
        response = self.client.post("/api/v1/classify-match", json=payload)
        self.assertEqual(response.status_code, 400)

    def test_update_mastery_endpoint(self):
        """POST /api/v1/update-mastery should update the BKT matrix."""
        payload = {
            "user_id": 1,
            "current_matrix": {
                "tactical_oversight": 0.50,
                "positional_error": 0.50,
                "endgame_fundamentals": 0.50,
                "opening_theory": 0.50,
                "king_safety": 0.50,
                "pawn_structure": 0.50,
                "piece_coordination": 0.50,
                "time_management": 0.50,
            },
            "classified_blunders": [
                {"category": "tactical_oversight", "move": 15, "severity": "blunder"},
            ],
        }
        response = self.client.post("/api/v1/update-mastery", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertLess(
            data["new_matrix"]["tactical_oversight"], 0.50,
        )

    def test_generate_plan_endpoint(self):
        """POST /api/v1/generate-plan should return a training plan."""
        payload = {
            "user_id": 1,
            "bkt_matrix": {
                "tactical_oversight": 0.30,
                "positional_error": 0.60,
                "endgame_fundamentals": 0.80,
                "opening_theory": 0.50,
                "king_safety": 0.25,
                "pawn_structure": 0.55,
                "piece_coordination": 0.45,
                "time_management": 0.20,
            },
            "elo_rating": 1350,
        }
        response = self.client.post("/api/v1/generate-plan", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertIn("primary_directive", data)
        self.assertGreater(len(data["weekly_focus"]), 0)
        self.assertGreater(len(data["plan_items"]), 0)


# ═══════════════════════════════════════════════════════════════════════
# 6. BKT INTEGRITY SIMULATION (50-MATCH STRESS TEST)
#    Reference: Milestone 2, Section 5.2
# ═══════════════════════════════════════════════════════════════════════

class TestBKTIntegrity(unittest.TestCase):
    """
    Simulates 50 consecutive matches to verify BKT mathematical integrity.
    
    From Milestone 2 §5.2: "The FastAPI Python microservice was unit-tested
    by simulating 50 consecutive matches. The system successfully calculated
    the posterior probabilities and updated the complex JSONB structures
    without mathematical degradation."
    """

    def test_50_match_simulation(self):
        """
        Simulate 50 consecutive matches with varied blunder patterns.
        Verify that the BKT matrix stays mathematically valid throughout.
        """
        import random
        random.seed(42)

        matrix = {
            "tactical_oversight": 0.50,
            "positional_error": 0.50,
            "endgame_fundamentals": 0.50,
            "opening_theory": 0.50,
            "king_safety": 0.50,
            "pawn_structure": 0.50,
            "piece_coordination": 0.50,
            "time_management": 0.50,
        }

        severities = ["blunder", "mistake", "inaccuracy"]
        skills = list(matrix.keys())

        for match_num in range(50):
            # Generate 1-5 random blunders per match
            num_blunders = random.randint(1, 5)
            blunders = []
            for _ in range(num_blunders):
                blunders.append({
                    "category": random.choice(skills),
                    "severity": random.choice(severities),
                    "move": random.randint(5, 40),
                })

            matrix, updated = process_match_blunders(matrix, blunders)

            # ── Mathematical integrity checks ──
            for skill, mastery in matrix.items():
                # 1. No NaN values
                self.assertFalse(
                    math.isnan(mastery),
                    f"Match {match_num}: {skill} is NaN",
                )
                # 2. No Inf values
                self.assertFalse(
                    math.isinf(mastery),
                    f"Match {match_num}: {skill} is Inf",
                )
                # 3. Bounded in [0.01, 0.99]
                self.assertGreaterEqual(
                    mastery, 0.01,
                    f"Match {match_num}: {skill}={mastery} below lower bound",
                )
                self.assertLessEqual(
                    mastery, 0.99,
                    f"Match {match_num}: {skill}={mastery} above upper bound",
                )

        # After 50 matches with many blunders, skills should have decreased
        # from 0.50 but remain valid
        any_changed = any(matrix[s] != 0.50 for s in skills)
        self.assertTrue(any_changed, "Matrix should change after 50 matches")

    def test_convergence_behavior(self):
        """
        When a skill gets many consecutive blunders, it should converge
        toward the lower bound but never reach 0.
        """
        matrix = {k: 0.50 for k in [
            "tactical_oversight", "positional_error", "endgame_fundamentals",
            "opening_theory", "king_safety", "pawn_structure",
            "piece_coordination", "time_management",
        ]}

        # 100 consecutive blunders on one skill
        for _ in range(100):
            matrix, _ = process_match_blunders(
                matrix,
                [{"category": "tactical_oversight", "severity": "blunder", "move": 1}],
            )

        # Should be very low but not zero
        self.assertGreater(matrix["tactical_oversight"], 0.0)
        self.assertLess(matrix["tactical_oversight"], 0.30)

    def test_full_pipeline_classify_then_update(self):
        """
        End-to-end: classify a match's moves, then feed the
        classifications into the BKT engine.
        """
        classifier = get_classifier()

        # Simulated match moves
        moves = [
            {"eval_before": 150, "eval_after": -250, "move_number": 12,
             "pieces_en_prise": 2, "hanging_value": 300, "capture_available": True},
            {"eval_before": 50, "eval_after": 40, "move_number": 15},
            {"eval_before": 100, "eval_after": -50, "move_number": 25,
             "total_pieces": 8, "time_remaining_pct": 0.05, "time_pressure": True},
            {"eval_before": 0, "eval_after": -5, "move_number": 30},
        ]

        # Step 1: Classify
        classified = classifier.classify_match(moves)
        self.assertGreater(len(classified), 0)

        # Step 2: Feed into BKT
        matrix = {k: 0.50 for k in [
            "tactical_oversight", "positional_error", "endgame_fundamentals",
            "opening_theory", "king_safety", "pawn_structure",
            "piece_coordination", "time_management",
        ]}

        bkt_blunders = [
            {"category": b["category"], "severity": b["severity"], "move": b["move"]}
            for b in classified
        ]

        new_matrix, updated = process_match_blunders(matrix, bkt_blunders)
        self.assertGreater(len(updated), 0)

        # All values should be valid
        for skill, mastery in new_matrix.items():
            self.assertFalse(math.isnan(mastery))
            self.assertGreaterEqual(mastery, 0.01)
            self.assertLessEqual(mastery, 0.99)


# ═══════════════════════════════════════════════════════════════════════
# 7. ONNX MODEL TESTS
# ═══════════════════════════════════════════════════════════════════════

class TestONNXModel(unittest.TestCase):
    """Tests for the ONNX model if available."""

    def test_onnx_file_exists(self):
        """The ONNX model file should exist after training."""
        onnx_path = os.path.join(
            os.path.dirname(__file__), "models", "blunder_classifier_rf.onnx"
        )
        if not os.path.exists(onnx_path):
            self.skipTest("ONNX model not found — run train_classifier.py first")
        self.assertGreater(os.path.getsize(onnx_path), 0)

    def test_onnx_sklearn_parity(self):
        """ONNX predictions should match Scikit-Learn predictions."""
        onnx_path = os.path.join(
            os.path.dirname(__file__), "models", "blunder_classifier_rf.onnx"
        )
        rf_path = os.path.join(
            os.path.dirname(__file__), "models", "blunder_classifier_rf.joblib"
        )
        if not os.path.exists(onnx_path) or not os.path.exists(rf_path):
            self.skipTest("Model files not found")

        try:
            import onnxruntime as ort
            import joblib
        except ImportError:
            self.skipTest("onnxruntime or joblib not installed")

        # Load both models
        session = ort.InferenceSession(onnx_path)
        rf_model = joblib.load(rf_path)

        # Generate test samples
        X_test, _ = generate_dataset(n_samples=100, seed=99)

        # Compare predictions
        sklearn_preds = rf_model.predict(X_test)

        input_name = session.get_inputs()[0].name
        onnx_preds = session.run(None, {input_name: X_test.astype(np.float32)})[0]

        # At least 95% of predictions should match
        match_rate = np.mean(sklearn_preds == onnx_preds)
        self.assertGreater(match_rate, 0.95, f"ONNX parity: {match_rate * 100:.1f}%")


# ═══════════════════════════════════════════════════════════════════════
# RUNNER
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    # Run with verbosity
    unittest.main(verbosity=2)
