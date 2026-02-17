"""Service orchestration for DR Agent MVP API.

This module centralizes event/proof/settlement workflows and maintains
an auditable SQLite index for query and hash re-check.
"""

from __future__ import annotations

import sqlite3
import uuid
from datetime import datetime, timezone

from services.db import connect
from services.dto import (
    AuditDTO,
    EventCreateRequest,
    EventDTO,
    ProofDTO,
    ProofSubmitRequest,
    SettlementDTO,
)
from services.proof_builder import build_proof_artifacts, recompute_hash
from services.scorer import calculate_payout


class ServiceError(Exception):
    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        retryable: bool = False,
        details: dict | None = None,
    ):
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message
        self.retryable = retryable
        self.details = details or {}


class SubmitterService:
    def __init__(self, db_path: str | None = None):
        self.conn = connect(db_path)

    def create_event(self, req: EventCreateRequest) -> EventDTO:
        start_time = _to_rfc3339(req.start_time)
        end_time = _to_rfc3339(req.end_time)
        if start_time >= end_time:
            raise ServiceError(400, "INVALID_TIME_WINDOW", "start_time must be < end_time")

        now = _utc_now()
        tx_hash = _tx_hash()

        try:
            self.conn.execute(
                """
                INSERT INTO events(event_id,start_time,end_time,target_kw,reward_rate,penalty_rate,status,tx_hash,created_at)
                VALUES(?,?,?,?,?,?,?,?,?)
                """,
                (
                    req.event_id,
                    start_time,
                    end_time,
                    req.target_kw,
                    req.reward_rate,
                    req.penalty_rate,
                    "active",
                    tx_hash,
                    now,
                ),
            )
            self.conn.commit()
        except sqlite3.IntegrityError as exc:
            raise ServiceError(409, "EVENT_EXISTS", "event_id already exists") from exc

        return EventDTO(
            event_id=req.event_id,
            start_time=start_time,
            end_time=end_time,
            target_kw=req.target_kw,
            reward_rate=req.reward_rate,
            penalty_rate=req.penalty_rate,
            status="active",
        )

    def get_event(self, event_id: str) -> EventDTO:
        row = self.conn.execute(
            """
            SELECT event_id,start_time,end_time,target_kw,reward_rate,penalty_rate,status
            FROM events WHERE event_id = ?
            """,
            (event_id,),
        ).fetchone()
        if row is None:
            raise ServiceError(404, "EVENT_NOT_FOUND", "event not found")
        return EventDTO(**dict(row))

    def submit_proof(self, req: ProofSubmitRequest, actor_id: str) -> ProofDTO:
        event = self.conn.execute(
            "SELECT status FROM events WHERE event_id = ?",
            (req.event_id,),
        ).fetchone()
        if event is None:
            raise ServiceError(404, "EVENT_NOT_FOUND", "event not found")
        if event["status"] != "active":
            raise ServiceError(409, "EVENT_NOT_ACTIVE", "event must be active")

        payload_json, computed_hash, reduction_kwh = build_proof_artifacts(
            event_id=req.event_id,
            site_id=req.site_id,
            baseline_kwh=req.baseline_kwh,
            actual_kwh=req.actual_kwh,
            baseline_method=req.baseline_method,
            raw_payload=req.raw_payload,
        )

        if req.proof_hash and req.proof_hash.lower() != computed_hash.lower():
            raise ServiceError(400, "PROOF_HASH_MISMATCH", "provided proof_hash does not match payload")

        submitted_at = _utc_now()

        try:
            self.conn.execute(
                """
                INSERT INTO proofs(
                    event_id,site_id,baseline_kwh,actual_kwh,reduction_kwh,proof_hash,
                    uri,payload,baseline_method,submitter,submitted_at
                ) VALUES(?,?,?,?,?,?,?,?,?,?,?)
                """,
                (
                    req.event_id,
                    req.site_id,
                    req.baseline_kwh,
                    req.actual_kwh,
                    reduction_kwh,
                    computed_hash,
                    req.uri,
                    payload_json,
                    req.baseline_method,
                    actor_id,
                    submitted_at,
                ),
            )
            self.conn.commit()
        except sqlite3.IntegrityError as exc:
            raise ServiceError(
                409,
                "PROOF_EXISTS",
                "proof already submitted for event_id + site_id",
            ) from exc

        return ProofDTO(
            event_id=req.event_id,
            site_id=req.site_id,
            baseline_kwh=req.baseline_kwh,
            actual_kwh=req.actual_kwh,
            reduction_kwh=reduction_kwh,
            proof_hash=computed_hash,
            uri=req.uri,
            submitted_at=submitted_at,
        )

    def settle_event(self, event_id: str, site_ids: list[str]) -> list[SettlementDTO]:
        event = self.conn.execute(
            """
            SELECT event_id,target_kw,reward_rate,penalty_rate,status
            FROM events WHERE event_id = ?
            """,
            (event_id,),
        ).fetchone()
        if event is None:
            raise ServiceError(404, "EVENT_NOT_FOUND", "event not found")

        if event["status"] == "settled":
            raise ServiceError(409, "EVENT_ALREADY_SETTLED", "event already settled")

        if event["status"] not in {"active", "closed"}:
            raise ServiceError(409, "INVALID_EVENT_STATE", "event cannot be settled from current state")

        if not site_ids:
            rows = self.conn.execute(
                "SELECT site_id FROM proofs WHERE event_id = ? ORDER BY site_id",
                (event_id,),
            ).fetchall()
            site_ids = [r["site_id"] for r in rows]

        if not site_ids:
            raise ServiceError(400, "EMPTY_SITE_IDS", "site_ids cannot be empty")

        target_share = event["target_kw"] // len(site_ids)
        now = _utc_now()

        self.conn.execute(
            "UPDATE events SET status = 'closed', closed_at = COALESCE(closed_at, ?) WHERE event_id = ?",
            (now, event_id),
        )

        created: list[SettlementDTO] = []
        for site_id in site_ids:
            proof = self.conn.execute(
                """
                SELECT reduction_kwh FROM proofs
                WHERE event_id = ? AND site_id = ?
                """,
                (event_id, site_id),
            ).fetchone()
            if proof is None:
                raise ServiceError(
                    400,
                    "PROOF_MISSING",
                    "proof missing for one or more site_ids",
                    details={"site_id": site_id},
                )

            existing = self.conn.execute(
                "SELECT 1 FROM settlements WHERE event_id = ? AND site_id = ?",
                (event_id, site_id),
            ).fetchone()
            if existing is not None:
                raise ServiceError(
                    409,
                    "ALREADY_SETTLED",
                    "settlement record already exists",
                    details={"site_id": site_id},
                )

            payout = calculate_payout(
                reduction_kwh=proof["reduction_kwh"],
                target_share=target_share,
                reward_rate=event["reward_rate"],
                penalty_rate=event["penalty_rate"],
            )

            tx_hash = _tx_hash()
            self.conn.execute(
                """
                INSERT INTO settlements(event_id,site_id,payout,status,settled_at,tx_hash)
                VALUES(?,?,?,?,?,?)
                """,
                (event_id, site_id, payout, "settled", now, tx_hash),
            )

            created.append(
                SettlementDTO(
                    event_id=event_id,
                    site_id=site_id,
                    payout=payout,
                    status="settled",
                    settled_at=now,
                    tx_hash=tx_hash,
                )
            )

        self.conn.execute(
            "UPDATE events SET status = 'settled', settled_at = ? WHERE event_id = ?",
            (now, event_id),
        )
        self.conn.commit()

        return created

    def claim_reward(self, event_id: str, site_id: str, actor_id: str) -> SettlementDTO:
        record = self.conn.execute(
            """
            SELECT event_id,site_id,payout,status,settled_at,tx_hash
            FROM settlements WHERE event_id = ? AND site_id = ?
            """,
            (event_id, site_id),
        ).fetchone()
        if record is None:
            raise ServiceError(404, "SETTLEMENT_NOT_FOUND", "settlement record not found")
        if record["status"] != "settled":
            raise ServiceError(409, "NOT_CLAIMABLE", "settlement is not claimable")

        proof = self.conn.execute(
            "SELECT submitter FROM proofs WHERE event_id = ? AND site_id = ?",
            (event_id, site_id),
        ).fetchone()
        if proof is None:
            raise ServiceError(404, "PROOF_NOT_FOUND", "proof not found")
        if proof["submitter"] != actor_id:
            raise ServiceError(403, "NOT_PROOF_SUBMITTER", "claimer is not proof submitter")

        claimed_at = _utc_now()
        self.conn.execute(
            """
            UPDATE settlements
            SET status = 'claimed', claimed_at = ?
            WHERE event_id = ? AND site_id = ?
            """,
            (claimed_at, event_id, site_id),
        )
        self.conn.commit()

        return SettlementDTO(
            event_id=record["event_id"],
            site_id=record["site_id"],
            payout=record["payout"],
            status="claimed",
            settled_at=record["settled_at"],
            tx_hash=record["tx_hash"],
        )

    def list_settlements(self, event_id: str) -> list[SettlementDTO]:
        rows = self.conn.execute(
            """
            SELECT event_id,site_id,payout,status,settled_at,tx_hash
            FROM settlements
            WHERE event_id = ?
            ORDER BY site_id
            """,
            (event_id,),
        ).fetchall()

        return [SettlementDTO(**dict(row)) for row in rows]

    def get_audit(self, event_id: str, site_id: str) -> AuditDTO:
        row = self.conn.execute(
            """
            SELECT event_id,site_id,proof_hash,uri,payload
            FROM proofs
            WHERE event_id = ? AND site_id = ?
            """,
            (event_id, site_id),
        ).fetchone()
        if row is None:
            raise ServiceError(404, "PROOF_NOT_FOUND", "proof not found")

        recomputed = recompute_hash(row["payload"])

        return AuditDTO(
            event_id=row["event_id"],
            site_id=row["site_id"],
            proof_hash_onchain=row["proof_hash"],
            proof_hash_recomputed=recomputed,
            match=row["proof_hash"].lower() == recomputed.lower(),
            raw_uri=row["uri"],
        )


def _utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _to_rfc3339(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    else:
        value = value.astimezone(timezone.utc)
    return value.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _tx_hash() -> str:
    return "0x" + uuid.uuid4().hex + uuid.uuid4().hex
