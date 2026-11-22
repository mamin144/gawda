# P0 Bootstrap Remediation Implementation Plan

## Goal

Bring the environment-bootstrap record into agreement with the repository's actual state, while preserving the owner's explicit decision to use the `flutter_bloc` package without a separate unavailable skill.

## Architecture

This is documentation and environment verification only. It does not create application code, database objects, or remote Supabase resources.

## Tech Stack

- Project-local skills under `.agents/skills/`
- PowerShell and Git for read-only verification
- Supabase CLI already installed globally

## Spec

1. Record the owner-approved BLoC exception and remove it from open questions.
2. Verify every P0 prerequisite from the actual filesystem and tool output, distinguishing local sandbox constraints from project failures.
3. Resolve only prerequisites that can be resolved safely and report any user action still required (notably OAuth authentication and Python installation).
4. Do not begin P1 until the P0 gate is explicitly approved after evidence is reported.

## Tasks

1. Update the decision and progress records for the BLoC exception.
2. Run focused tool, repository, secrets, and configuration checks.
3. Request the minimal authorization needed for a CLI verification that writes its normal local telemetry file, if required.
4. Record evidence and commit the documentation-only remediation as one P0 task.
