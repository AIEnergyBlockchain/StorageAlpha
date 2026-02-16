"""Baseline computation for DR Agent.

Two methods:
1. Simple 7-day same-hour average (fallback)
2. Prophet forecast (primary)
"""

import logging

import pandas as pd

logger = logging.getLogger(__name__)


def compute_baseline_simple(history_df: pd.DataFrame, event_hour: int) -> float:
    """Compute baseline as 7-day same-hour average.

    Args:
        history_df: DataFrame with columns (timestamp, kw).
        event_hour: Hour of day (0-23) for the DR event.

    Returns:
        Baseline power in kW.
    """
    df = history_df.copy()
    df["hour"] = pd.to_datetime(df["timestamp"]).dt.hour

    # Last 7 days
    cutoff = pd.to_datetime(df["timestamp"]).max() - pd.Timedelta(days=7)
    recent = df[pd.to_datetime(df["timestamp"]) >= cutoff]

    same_hour = recent[recent["hour"] == event_hour]
    if same_hour.empty:
        return float(df["kw"].mean())

    return float(same_hour["kw"].mean())


def compute_baseline_prophet(
    history_df: pd.DataFrame,
    event_start: str,
    event_end: str,
) -> float:
    """Compute baseline using Prophet forecast.

    Falls back to simple method on failure.

    Args:
        history_df: DataFrame with columns (timestamp, kw).
        event_start: Event start time (ISO format string).
        event_end: Event end time (ISO format string).

    Returns:
        Baseline power in kW (average over event window).
    """
    try:
        from prophet import Prophet

        # Prepare data for Prophet
        df = history_df[["timestamp", "kw"]].copy()
        df.columns = ["ds", "y"]
        df["ds"] = pd.to_datetime(df["ds"])

        model = Prophet(daily_seasonality=True, weekly_seasonality=True)
        model.fit(df)

        # Create future dataframe for the event window
        future_start = pd.Timestamp(event_start)
        future_end = pd.Timestamp(event_end)
        future = pd.date_range(start=future_start, end=future_end, freq="15min")
        future_df = pd.DataFrame({"ds": future})

        forecast = model.predict(future_df)
        baseline = float(forecast["yhat"].mean())

        logger.info("Prophet baseline: %.2f kW", baseline)
        return baseline

    except Exception as e:
        logger.warning("Prophet failed (%s), falling back to simple method", e)
        event_hour = pd.Timestamp(event_start).hour
        return compute_baseline_simple(history_df, event_hour)
