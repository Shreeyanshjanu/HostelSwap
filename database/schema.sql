-- HostelSwap Database Schema
-- Run this in Supabase SQL Editor

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Users ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    college_id      TEXT        PRIMARY KEY,
    name            TEXT,
    gender          TEXT        NOT NULL CHECK (gender IN (''male'', ''female'', ''other'')),
    phone           TEXT,
    fcm_token       TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Swap Requests ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS requests (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         TEXT        NOT NULL REFERENCES users(college_id) ON DELETE CASCADE,
    current_hostel  TEXT        NOT NULL,
    current_ac      BOOLEAN     NOT NULL,
    current_seater  INT         NOT NULL CHECK (current_seater IN (2,3,4,5)),
    desired_hostel  TEXT        NOT NULL,
    desired_ac      BOOLEAN,
    desired_seater  INT         CHECK (desired_seater IN (2,3,4,5)),
    status          TEXT        NOT NULL DEFAULT ''active'' CHECK (status IN (''active'',''matched'',''withdrawn'',''expired'')),
    gender          TEXT        NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_requests_status  ON requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_gender  ON requests(gender);
CREATE INDEX IF NOT EXISTS idx_requests_user_id ON requests(user_id);

-- ── Interests ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS interests (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id      UUID        NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    applicant_id    TEXT        NOT NULL REFERENCES users(college_id) ON DELETE CASCADE,
    message         TEXT,
    status          TEXT        NOT NULL DEFAULT ''pending'' CHECK (status IN (''pending'',''accepted'',''rejected'')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (request_id, applicant_id)
);

-- ── Chat Unlocks (Audit log) ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_unlocks (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id      UUID        NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    requester_id    TEXT        NOT NULL REFERENCES users(college_id),
    applicant_id    TEXT        NOT NULL REFERENCES users(college_id),
    unlocked_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── Finalizations ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS finalizations (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id      UUID        NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    requester_id    TEXT        NOT NULL REFERENCES users(college_id),
    applicant_id    TEXT        NOT NULL REFERENCES users(college_id),
    initiated_at    TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,
    is_completed    BOOLEAN     NOT NULL DEFAULT FALSE
);
