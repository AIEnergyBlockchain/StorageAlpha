"""Simulated load data generator for DR Agent."""

import numpy as np
import pandas as pd


def generate_load_data(days: int = 30, interval_min: int = 15) -> pd.DataFrame:
    """Generate simulated load data with daily patterns and noise.

    Args:
        days: Number of historical days to generate.
        interval_min: Sampling interval in minutes.

    Returns:
        DataFrame with columns: timestamp (datetime), kw (float).
    """
    periods = days * 24 * (60 // interval_min)
    timestamps = pd.date_range(
        end=pd.Timestamp.now().floor("h"),
        periods=periods,
        freq=f"{interval_min}min",
    )

    hours = timestamps.hour + timestamps.minute / 60.0

    # Base load ~200 kW
    base = 200.0

    # Daily pattern: peak around 14:00, trough around 04:00
    daily_pattern = 80 * np.sin(np.pi * (hours - 6) / 12)
    daily_pattern = np.clip(daily_pattern, -40, 80)

    # Weekday vs weekend factor
    weekday_factor = np.where(timestamps.weekday < 5, 1.0, 0.7)

    # Random noise
    noise = np.random.normal(0, 15, size=periods)

    kw = (base + daily_pattern) * weekday_factor + noise
    kw = np.clip(kw, 50, 500)

    return pd.DataFrame({"timestamp": timestamps, "kw": kw})
