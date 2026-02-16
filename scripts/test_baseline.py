"""Verification script: compare Prophet vs simple baseline methods."""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pandas as pd

from services.collector import generate_load_data
from services.baseline import compute_baseline_simple, compute_baseline_prophet


def main():
    print("=== DR Agent Baseline Verification ===\n")

    # Generate 30 days of simulated load data
    print("Generating 30 days of simulated load data (15-min intervals)...")
    history = generate_load_data(days=30)
    print(f"  Records: {len(history)}")
    print(f"  Range: {history['timestamp'].min()} -> {history['timestamp'].max()}")
    print(f"  Mean kW: {history['kw'].mean():.2f}")
    print()

    # Define event window: tomorrow 14:00-15:00
    last_ts = history["timestamp"].max()
    event_start = (last_ts + pd.Timedelta(hours=1)).strftime("%Y-%m-%d %H:%M:%S")
    event_end = (last_ts + pd.Timedelta(hours=2)).strftime("%Y-%m-%d %H:%M:%S")
    event_hour = pd.Timestamp(event_start).hour

    print(f"Event window: {event_start} -> {event_end}")
    print(f"Event hour: {event_hour}")
    print()

    # Method 1: Simple average
    simple = compute_baseline_simple(history, event_hour)
    print(f"[Simple] 7-day same-hour average baseline: {simple:.2f} kW")

    # Method 2: Prophet forecast
    print("\n[Prophet] Training model (this may take a moment)...")
    prophet = compute_baseline_prophet(history, event_start, event_end)
    print(f"[Prophet] Forecast baseline: {prophet:.2f} kW")

    # Comparison
    diff = prophet - simple
    pct = (diff / simple) * 100 if simple != 0 else 0
    print(f"\nDifference: {diff:+.2f} kW ({pct:+.1f}%)")
    print("\n=== Done ===")


if __name__ == "__main__":
    main()
