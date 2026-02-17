"""Settlement scoring utilities for DR Agent MVP."""

from __future__ import annotations


def calculate_payout(
    reduction_kwh: int,
    target_share: int,
    reward_rate: int,
    penalty_rate: int,
) -> int:
    """Calculate payout using README MVP formula.

    payout = target_share * reward_rate, if reduction >= target_share
    else payout = reduction * reward_rate - (target_share - reduction) * penalty_rate
    """
    if reduction_kwh >= target_share:
        return target_share * reward_rate

    reward = reduction_kwh * reward_rate
    penalty = (target_share - reduction_kwh) * penalty_rate
    return reward - penalty
