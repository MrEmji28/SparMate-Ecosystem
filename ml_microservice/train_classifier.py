#!/usr/bin/env python3
"""
SparMate Blunder Classifier — Training Pipeline

Trains a Random Forest and Support Vector Machine (SVM) classifier to
categorize chess mistakes into 8 cognitive skill categories. This is the
core ML pipeline described in Milestone 2, Sections 4.4 and 5.2.

Usage:
    cd ml_microservice
    python train_classifier.py

Outputs:
    models/blunder_classifier_rf.joblib     — Trained Random Forest model
    models/blunder_classifier_svm.joblib    — Trained SVM model
    models/blunder_classifier_rf.onnx       — ONNX export of RF model
    models/evaluation_report.txt            — Classification metrics report

Architecture:
    1. Generate training data (simulating Lichess intermediate games)
    2. Train Random Forest (primary) and SVM (secondary) classifiers
    3. Evaluate on held-out test set (accuracy, F1, precision, recall)
    4. Export the best model to ONNX format for mobile edge inference
    5. Save evaluation metrics for the academic report
"""

import os
import sys
import json
import time
import numpy as np

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
import joblib

from data_generator import (
    generate_dataset,
    CATEGORIES,
    NUM_CATEGORIES,
    INDEX_TO_CATEGORY,
)
from feature_engineering import FEATURE_NAMES, NUM_FEATURES


# ── Configuration ────────────────────────────────────────────────────────

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
TRAIN_SAMPLES = 10000    # Total training + validation samples
TEST_RATIO = 0.2         # 20% held out for testing
RANDOM_SEED = 42


def ensure_models_dir():
    """Create the models directory if it doesn't exist."""
    os.makedirs(MODELS_DIR, exist_ok=True)


# ── Training Pipeline ────────────────────────────────────────────────────

def train_random_forest(X_train, y_train) -> Pipeline:
    """
    Train a Random Forest classifier with StandardScaler preprocessing.

    Random Forest is the primary model due to:
    - Strong performance on tabular data with mixed feature types
    - Built-in feature importance for interpretability
    - Robust to outliers and noisy features
    - Fast inference suitable for edge deployment
    """
    print("\n" + "=" * 60)
    print("Training Random Forest Classifier")
    print("=" * 60)

    pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", RandomForestClassifier(
            n_estimators=200,
            max_depth=18,
            min_samples_split=5,
            min_samples_leaf=2,
            max_features="sqrt",
            random_state=RANDOM_SEED,
            n_jobs=-1,
            class_weight="balanced",
        )),
    ])

    start = time.time()
    pipeline.fit(X_train, y_train)
    elapsed = time.time() - start

    print(f"  Training time: {elapsed:.2f}s")
    print(f"  Estimators:    {pipeline.named_steps['clf'].n_estimators}")
    print(f"  Max depth:     {pipeline.named_steps['clf'].max_depth}")

    # Cross-validation on training set
    cv_scores = cross_val_score(pipeline, X_train, y_train, cv=5, scoring="accuracy")
    print(f"  CV Accuracy:   {cv_scores.mean():.4f} (±{cv_scores.std():.4f})")

    return pipeline


def train_svm(X_train, y_train) -> Pipeline:
    """
    Train a Support Vector Machine classifier with RBF kernel.

    SVM serves as the secondary model for comparison, per Milestone 2
    which specified "Random Forest / Multi-class SVM model."
    """
    print("\n" + "=" * 60)
    print("Training SVM Classifier (RBF Kernel)")
    print("=" * 60)

    pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", SVC(
            kernel="rbf",
            C=10.0,
            gamma="scale",
            random_state=RANDOM_SEED,
            class_weight="balanced",
            decision_function_shape="ovr",
            probability=True,
        )),
    ])

    start = time.time()
    pipeline.fit(X_train, y_train)
    elapsed = time.time() - start

    print(f"  Training time: {elapsed:.2f}s")
    print(f"  Kernel:        {pipeline.named_steps['clf'].kernel}")
    print(f"  C:             {pipeline.named_steps['clf'].C}")

    # Cross-validation
    cv_scores = cross_val_score(pipeline, X_train, y_train, cv=5, scoring="accuracy")
    print(f"  CV Accuracy:   {cv_scores.mean():.4f} (±{cv_scores.std():.4f})")

    return pipeline


# ── Evaluation ───────────────────────────────────────────────────────────

def evaluate_model(
    model: Pipeline,
    X_test: np.ndarray,
    y_test: np.ndarray,
    model_name: str,
) -> dict:
    """
    Evaluate a trained model on the test set.

    Returns a dict of metrics matching the Milestone 2 report requirements:
    - Overall accuracy (target: > 85%)
    - F1-score (target: > 0.85)
    - Per-class precision, recall, F1
    - Confusion matrix
    """
    print(f"\n{'─' * 60}")
    print(f"Evaluation: {model_name}")
    print(f"{'─' * 60}")

    y_pred = model.predict(X_test)

    accuracy = accuracy_score(y_test, y_pred)
    f1_macro = f1_score(y_test, y_pred, average="macro")
    f1_weighted = f1_score(y_test, y_pred, average="weighted")
    precision = precision_score(y_test, y_pred, average="macro")
    recall = recall_score(y_test, y_pred, average="macro")

    print(f"\n  Overall Accuracy:    {accuracy:.4f} ({accuracy * 100:.1f}%)")
    print(f"  F1 Score (macro):    {f1_macro:.4f}")
    print(f"  F1 Score (weighted): {f1_weighted:.4f}")
    print(f"  Precision (macro):   {precision:.4f}")
    print(f"  Recall (macro):      {recall:.4f}")

    # Per-class report
    report = classification_report(
        y_test, y_pred,
        target_names=CATEGORIES,
        digits=3,
    )
    print(f"\n  Per-class Classification Report:\n{report}")

    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    print(f"  Confusion Matrix:")
    header = "  " + " ".join(f"{cat[:6]:>7}" for cat in CATEGORIES)
    print(header)
    for i, row in enumerate(cm):
        row_str = " ".join(f"{v:7d}" for v in row)
        print(f"  {CATEGORIES[i][:6]:>6} {row_str}")

    return {
        "model_name": model_name,
        "accuracy": round(accuracy, 4),
        "f1_macro": round(f1_macro, 4),
        "f1_weighted": round(f1_weighted, 4),
        "precision_macro": round(precision, 4),
        "recall_macro": round(recall, 4),
        "classification_report": report,
        "confusion_matrix": cm.tolist(),
    }


def get_feature_importances(model: Pipeline, top_n: int = 10) -> list[tuple[str, float]]:
    """Extract top feature importances from Random Forest model."""
    if not hasattr(model.named_steps["clf"], "feature_importances_"):
        return []

    importances = model.named_steps["clf"].feature_importances_
    indices = np.argsort(importances)[::-1][:top_n]

    result = []
    for idx in indices:
        result.append((FEATURE_NAMES[idx], round(importances[idx], 4)))

    return result


# ── ONNX Export ──────────────────────────────────────────────────────────

def export_to_onnx(model: Pipeline, model_path: str):
    """
    Export the trained Scikit-Learn pipeline to ONNX format.

    This implements the ONNX conversion described in Milestone 2, Section 4.4:
    "I exported the trained Scikit-Learn pipeline into an Open Neural Network
    Exchange (.onnx) format."

    The ONNX model can be loaded on mobile devices via ONNX Runtime for
    offline, edge-based blunder classification.
    """
    try:
        from skl2onnx import convert_sklearn
        from skl2onnx.common.data_types import FloatTensorType

        initial_type = [("float_input", FloatTensorType([None, NUM_FEATURES]))]

        onnx_model = convert_sklearn(
            model,
            initial_types=initial_type,
            target_opset=12,
            options={
                id(model.named_steps["clf"]): {
                    "zipmap": False  # Return raw probabilities, not dict
                }
            } if hasattr(model.named_steps["clf"], "predict_proba") else None,
        )

        with open(model_path, "wb") as f:
            f.write(onnx_model.SerializeToString())

        print(f"\n  ✅ ONNX model exported: {model_path}")
        print(f"     Size: {os.path.getsize(model_path) / 1024:.1f} KB")
        return True

    except ImportError:
        print("\n  ⚠️  skl2onnx not installed. Skipping ONNX export.")
        print("     Install with: pip install skl2onnx")
        return False


def verify_onnx(model_path: str, X_test: np.ndarray, y_test: np.ndarray):
    """Verify the ONNX model produces consistent predictions."""
    try:
        import onnxruntime as ort

        session = ort.InferenceSession(model_path)
        input_name = session.get_inputs()[0].name

        # Run inference
        X_sample = X_test[:100].astype(np.float32)
        results = session.run(None, {input_name: X_sample})
        onnx_preds = results[0]

        # Check accuracy
        onnx_accuracy = accuracy_score(y_test[:100], onnx_preds)
        print(f"  ✅ ONNX verification: {onnx_accuracy * 100:.1f}% accuracy on 100 samples")
        return True

    except ImportError:
        print("  ⚠️  onnxruntime not installed. Skipping ONNX verification.")
        return False
    except Exception as e:
        print(f"  ❌ ONNX verification failed: {e}")
        return False


# ── Save Results ─────────────────────────────────────────────────────────

def save_evaluation_report(rf_metrics: dict, svm_metrics: dict, importances: list):
    """Save a formatted evaluation report for the academic paper."""
    report_path = os.path.join(MODELS_DIR, "evaluation_report.txt")

    with open(report_path, "w") as f:
        f.write("=" * 70 + "\n")
        f.write("SparMate Blunder Classifier — Evaluation Report\n")
        f.write("=" * 70 + "\n\n")

        f.write("Dataset: 10,000 intermediate-level chess game blunders\n")
        f.write(f"Training set: {int(TRAIN_SAMPLES * (1 - TEST_RATIO))} samples\n")
        f.write(f"Test set:     {int(TRAIN_SAMPLES * TEST_RATIO)} samples\n")
        f.write(f"Features:     {NUM_FEATURES}\n")
        f.write(f"Classes:      {NUM_CATEGORIES}\n\n")

        for metrics in [rf_metrics, svm_metrics]:
            f.write(f"{'─' * 50}\n")
            f.write(f"Model: {metrics['model_name']}\n")
            f.write(f"{'─' * 50}\n")
            f.write(f"  Accuracy:          {metrics['accuracy'] * 100:.1f}%\n")
            f.write(f"  F1 (macro):        {metrics['f1_macro']:.4f}\n")
            f.write(f"  F1 (weighted):     {metrics['f1_weighted']:.4f}\n")
            f.write(f"  Precision (macro): {metrics['precision_macro']:.4f}\n")
            f.write(f"  Recall (macro):    {metrics['recall_macro']:.4f}\n\n")
            f.write(metrics["classification_report"])
            f.write("\n\n")

        if importances:
            f.write(f"{'─' * 50}\n")
            f.write("Top Feature Importances (Random Forest)\n")
            f.write(f"{'─' * 50}\n")
            for name, importance in importances:
                bar = "█" * int(importance * 100)
                f.write(f"  {name:<30} {importance:.4f}  {bar}\n")

    print(f"\n  📄 Report saved: {report_path}")


# ── Main Pipeline ────────────────────────────────────────────────────────

def main():
    """Execute the full training pipeline."""
    print("╔" + "═" * 58 + "╗")
    print("║   SparMate Blunder Classifier — Training Pipeline       ║")
    print("║   Milestone 2, Section 4.4 Implementation               ║")
    print("╚" + "═" * 58 + "╝")

    ensure_models_dir()

    # ── Step 1: Generate Training Data ──
    print("\n📊 Step 1: Generating training data...")
    print(f"   Samples: {TRAIN_SAMPLES}")
    print(f"   Features: {NUM_FEATURES}")
    print(f"   Classes: {NUM_CATEGORIES}")

    X, y = generate_dataset(n_samples=TRAIN_SAMPLES, seed=RANDOM_SEED)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=TEST_RATIO, random_state=RANDOM_SEED, stratify=y,
    )

    print(f"   Train: {X_train.shape[0]} samples")
    print(f"   Test:  {X_test.shape[0]} samples")
    print(f"   Class distribution (train): {dict(zip(*np.unique(y_train, return_counts=True)))}")

    # ── Step 2: Train Models ──
    print("\n🧠 Step 2: Training models...")
    rf_model = train_random_forest(X_train, y_train)
    svm_model = train_svm(X_train, y_train)

    # ── Step 3: Evaluate ──
    print("\n📈 Step 3: Evaluating on test set...")
    rf_metrics = evaluate_model(rf_model, X_test, y_test, "Random Forest")
    svm_metrics = evaluate_model(svm_model, X_test, y_test, "SVM (RBF Kernel)")

    # ── Step 4: Feature Importances ──
    importances = get_feature_importances(rf_model, top_n=15)
    if importances:
        print(f"\n🔍 Top 15 Feature Importances:")
        for name, imp in importances:
            bar = "█" * int(imp * 200)
            print(f"   {name:<30} {imp:.4f}  {bar}")

    # ── Step 5: Save Models ──
    print("\n💾 Step 5: Saving models...")
    rf_path = os.path.join(MODELS_DIR, "blunder_classifier_rf.joblib")
    svm_path = os.path.join(MODELS_DIR, "blunder_classifier_svm.joblib")

    joblib.dump(rf_model, rf_path)
    joblib.dump(svm_model, svm_path)
    print(f"   Saved: {rf_path}")
    print(f"   Saved: {svm_path}")

    # ── Step 6: ONNX Export ──
    print("\n📦 Step 6: Exporting to ONNX format...")
    onnx_path = os.path.join(MODELS_DIR, "blunder_classifier_rf.onnx")
    onnx_exported = export_to_onnx(rf_model, onnx_path)

    if onnx_exported:
        verify_onnx(onnx_path, X_test, y_test)

    # ── Step 7: Save Report ──
    print("\n📄 Step 7: Saving evaluation report...")
    save_evaluation_report(rf_metrics, svm_metrics, importances)

    # ── Summary ──
    print("\n" + "═" * 60)
    print("TRAINING COMPLETE")
    print("═" * 60)
    print(f"  Random Forest Accuracy: {rf_metrics['accuracy'] * 100:.1f}%")
    print(f"  Random Forest F1:       {rf_metrics['f1_macro']:.4f}")
    print(f"  SVM Accuracy:           {svm_metrics['accuracy'] * 100:.1f}%")
    print(f"  SVM F1:                 {svm_metrics['f1_macro']:.4f}")
    print(f"  ONNX Exported:          {'Yes' if onnx_exported else 'No (install skl2onnx)'}")
    print(f"  Models saved to:        {MODELS_DIR}/")
    print()

    # Save metadata
    metadata = {
        "train_samples": X_train.shape[0],
        "test_samples": X_test.shape[0],
        "num_features": NUM_FEATURES,
        "num_classes": NUM_CATEGORIES,
        "categories": CATEGORIES,
        "feature_names": FEATURE_NAMES,
        "random_forest": rf_metrics,
        "svm": svm_metrics,
        "feature_importances": importances,
        "onnx_exported": onnx_exported,
    }
    # Remove non-serializable items
    for model_key in ["random_forest", "svm"]:
        if "classification_report" in metadata[model_key]:
            del metadata[model_key]["classification_report"]

    meta_path = os.path.join(MODELS_DIR, "training_metadata.json")
    with open(meta_path, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"  Metadata saved:         {meta_path}")


if __name__ == "__main__":
    main()
