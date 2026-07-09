# DSG API Reference

**Complete endpoint and SDK documentation for policy execution, evidence retrieval, and governance.**

---

## Base URL

```
https://tdealer01-crypto-dsg-control-plane.vercel.app/api/dsg-one
```

All endpoints require authentication except `/readiness` and `/health`.

---

## Authentication

Include the `Authorization` header with a valid session token:

```bash
Authorization: Bearer <YOUR_SESSION_TOKEN>
```

Tokens are obtained via NextAuth.js. The default provider is GitHub.

---

## Core Endpoints

### 1. Execute Policy Decision

**Execute a policy-governed decision with formal verification.**

```http
POST /determinism/execute
Content-Type: application/json
Authorization: Bearer <token>

{
  "policyId": "pol_task_assignment_v2",
  "context": {
    "tasks": [
      { "id": "task-1", "complexity": 8, "duration": 4 },
      { "id": "task-2", "complexity": 5, "duration": 3 }
    ],
    "agents": [
      { "id": "agent-a", "capacity": 10 },
      { "id": "agent-b", "capacity": 8 }
    ],
    "constraints": ["max_overload:2", "prefer_balance:true"]
  },
  "options": {
    "timeout": 5000,
    "solverMode": "ising-verify"
  }
}
```

**Response (Success):**

```json
{
  "ok": true,
  "decision": {
    "assignments": [
      { "task": "task-1", "agent": "agent-a" },
      { "task": "task-2", "agent": "agent-b" }
    ],
    "isValid": true,
    "energy": -42.5
  },
  "proof": {
    "decisionHash": "sha256:abc123def456...",
    "solverUsed": "ising-verify",
    "solverVersion": "nvidia-ising-v1",
    "timestamp": "2026-07-09T23:08:58.256Z"
  },
  "ledgerId": "ledger_abc123xyz789",
  "metadata": {
    "executionTimeMs": 1247,
    "constraintsSatisfied": 14,
    "determinismScore": 100
  }
}
```

**Response (Unsat):**

```json
{
  "ok": true,
  "decision": null,
  "reason": "UNSAT",
  "message": "Constraints cannot be simultaneously satisfied. Conflicting constraints: max_overload vs prefer_balance",
  "ledgerId": "ledger_abc123xyz789"
}
```

**Status Codes:**
- `200` — Decision executed successfully
- `400` — Invalid policy or context
- `401` — Unauthorized (missing/invalid token)
- `408` — Solver timeout (exceeded `options.timeout`)
- `500` — Internal server error

---

### 2. Record Evidence to Ledger

**Manually record a decision with cryptographic proof.**

```http
POST /determinism/record
Content-Type: application/json
Authorization: Bearer <token>

{
  "policyId": "pol_payment_approval",
  "decision": {
    "paymentId": "pay_xyz123",
    "approved": true,
    "amount": 5000,
    "reason": "Within tier-1 approval limit"
  },
  "proof": {
    "type": "z3-sat",
    "hash": "sha256:abc123...",
    "verificationTime": 247
  },
  "ccvsLevel": 4,
  "metadata": {
    "requestId": "req_123",
    "userId": "user_abc",
    "ipAddress": "203.0.113.42"
  }
}
```

**Response:**

```json
{
  "ok": true,
  "ledgerId": "ledger_record_xyz789",
  "merkleRoot": "sha256:merkle_tree_root_hash",
  "blockNumber": 12847,
  "timestamp": "2026-07-09T23:09:15.000Z",
  "ccvsArtifacts": {
    "L1": { "decision": "approved", "timestamp": "..." },
    "L2": { "policyId": "pol_payment_approval", "version": 2 },
    "L3": { "z3Proof": "...", "verifyTime": 247 },
    "L4": { "merklePath": "[...]", "proofHash": "..." },
    "L5": { "signature": "...", "signedBy": "dsg-core@..." }
  }
}
```

---

### 3. Retrieve Decision Proof

**Fetch the cryptographic proof and evidence for a recorded decision.**

```http
GET /determinism/proof?ledgerId=ledger_record_xyz789
Authorization: Bearer <token>
```

**Response:**

```json
{
  "ok": true,
  "ledgerId": "ledger_record_xyz789",
  "decision": {
    "policyId": "pol_payment_approval",
    "approved": true,
    "recordedAt": "2026-07-09T23:09:15.000Z"
  },
  "proof": {
    "decisionHash": "sha256:abc123...",
    "solverUsed": "z3",
    "solverVersion": "4.8.12",
    "z3Proof": "...",
    "verificationTime": 247
  },
  "merkleChain": {
    "currentRoot": "sha256:merkle_root",
    "previousRoot": "sha256:previous_root",
    "blockNumber": 12847,
    "path": ["sha256:hash1", "sha256:hash2", "..."]
  },
  "verifiable": true,
  "replayable": true
}
```

---

### 4. Verify Audit Trail Integrity

**Verify the Merkle chain to ensure no tampering.**

```http
POST /determinism/verify-audit-trail
Content-Type: application/json
Authorization: Bearer <token>

{
  "startLedgerId": "ledger_record_abc",
  "endLedgerId": "ledger_record_xyz",
  "expectedBlockCount": 47
}
```

**Response:**

```json
{
  "ok": true,
  "verified": true,
  "blockCount": 47,
  "merkleRootMatch": true,
  "integrity": {
    "tamperingDetected": false,
    "missingBlocks": 0,
    "inconsistencies": []
  },
  "verification": {
    "method": "merkle-chain-reconstruction",
    "timestamp": "2026-07-09T23:10:00.000Z"
  }
}
```

---

### 5. Policy Execution Flow

**Execute a complete policy workflow (constraint validation + decision + evidence).**

```http
POST /policy/execute-flow
Content-Type: application/json
Authorization: Bearer <token>

{
  "policyId": "pol_task_routing_v1",
  "flowSteps": [
    {
      "step": "validate_constraints",
      "constraints": ["team_size_max:5", "task_duration_min:1h"]
    },
    {
      "step": "solve_assignment",
      "solverMode": "ising-verify",
      "timeout": 3000
    },
    {
      "step": "record_evidence",
      "ccvsLevel": 3
    }
  ],
  "context": {
    "tasks": [...],
    "agents": [...],
    "options": {...}
  }
}
```

**Response:** Combined output of all steps with full proof chain.

---

## NVIDIA Ising Integration

### 6. Analyze with LLM (Advisory)

**Optional: Run NVIDIA LLM analysis on a solver result (advisory only).**

Requires `NVIDIA_LLM_VERIFIER_MODE=advisory` and valid `NVIDIA_API_KEY`.

```http
POST /ising/analyze-with-llm
Content-Type: application/json
Authorization: Bearer <token>

{
  "solverResult": {
    "assignments": [...],
    "energy": -42.5,
    "confidence": 0.87
  },
  "policyContext": {
    "constraints": ["max_overload:2", "fairness:high"],
    "objectives": ["minimize_latency", "balance_load"]
  }
}
```

**Response:**

```json
{
  "ok": true,
  "llmAnalysis": {
    "verdict": "agrees",
    "reasoning": "Solution respects all hard constraints and optimizes for stated objectives.",
    "confidence": 0.89,
    "flags": []
  },
  "determinativeDecision": {
    "approved": true,
    "proof": "sha256:...",
    "reason": "Deterministic solver verdict confirmed by LLM analysis"
  },
  "llmResponseTime": 1240
}
```

---

### 7. Benchmark Ising vs Z3

**Trigger a performance benchmark run.**

```http
POST /ising/benchmark
Content-Type: application/json
Authorization: Bearer <token>

{
  "problemSize": "medium",  // small | medium | large
  "repetitions": 5,
  "solverModes": ["z3-only", "ising-verify", "ising-warmstart"]
}
```

**Response:**

```json
{
  "ok": true,
  "benchmarkId": "bench_xyz789",
  "status": "running",
  "estimatedDuration": "45s",
  "progress": {
    "completed": 3,
    "total": 15
  },
  "pollUrl": "/ising/benchmark?benchmarkId=bench_xyz789"
}
```

Fetch results:
```http
GET /ising/benchmark?benchmarkId=bench_xyz789
```

**Benchmark Results:**

```json
{
  "ok": true,
  "benchmarkId": "bench_xyz789",
  "status": "completed",
  "results": {
    "small": {
      "z3-only": {
        "avgLatency": 245,
        "deterministicScore": 100,
        "speedImprovement": null
      },
      "ising-verify": {
        "avgLatency": 187,
        "deterministicScore": 100,
        "speedImprovement": "23.7%"
      }
    }
  },
  "report": "s3://bucket/reports/bench_xyz789.md"
}
```

---

## Health & Monitoring

### 8. Health Check

**Check service status (no auth required).**

```http
GET /health
```

**Response:**

```json
{
  "ok": true,
  "service": "dsg-control-plane",
  "timestamp": "2026-07-09T23:08:58.256Z",
  "core_ok": true,
  "db_ok": true
}
```

---

### 9. Readiness Check

**Verify all systems ready for production traffic (no auth required).**

```http
GET /readiness
```

**Response:**

```json
{
  "ok": true,
  "checks": {
    "env": { "ok": true },
    "nextAuthSecret": { "ok": true },
    "supabaseServiceRole": { "ok": true },
    "dsgCoreConfig": { "ok": true },
    "dsgCoreHealth": { "ok": true }
  }
}
```

---

## SDK: TypeScript Client

### Installation

```bash
npm install @dsg/client
```

### Usage

```typescript
import { DSGClient } from '@dsg/client'

const client = new DSGClient({
  baseUrl: 'https://api.example.com/api/dsg-one',
  token: process.env.DSG_TOKEN
})

// Execute a policy
const result = await client.executePolicy({
  policyId: 'pol_task_assignment',
  context: {
    tasks: [...],
    agents: [...]
  },
  options: { timeout: 5000 }
})

if (result.ok) {
  console.log('Decision:', result.decision)
  console.log('Proof:', result.proof)
  console.log('Ledger ID:', result.ledgerId)
}

// Retrieve proof later
const proof = await client.getProof(result.ledgerId)
console.log('Proof hash:', proof.proof.decisionHash)
```

---

## Error Handling

All error responses follow this format:

```json
{
  "ok": false,
  "error": {
    "code": "CONSTRAINT_UNSAT",
    "message": "Constraints cannot be simultaneously satisfied",
    "details": {
      "conflictingConstraints": ["max_overload", "prefer_balance"],
      "solverOutput": "..."
    }
  }
}
```

### Common Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| `INVALID_POLICY` | Policy not found or malformed | Check policy ID |
| `CONSTRAINT_UNSAT` | No solution satisfies all constraints | Relax constraints |
| `SOLVER_TIMEOUT` | Solver exceeded time limit | Increase timeout or reduce problem size |
| `AUTH_INVALID` | Token missing or expired | Re-authenticate |
| `RATE_LIMIT` | Too many requests | Implement exponential backoff |
| `INTERNAL_ERROR` | Server error (rare) | Retry with exponential backoff |

---

## Rate Limiting

All endpoints are rate limited:

- **Public endpoints** (`/health`, `/readiness`): 100 req/min per IP
- **Authenticated endpoints**: 1000 req/min per user
- **Solver endpoints** (`/determinism/execute`): 10 req/min per user (solver is expensive)

Headers returned on every response:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1626124800
```

---

## Webhooks (Optional)

Register for decision webhooks to receive notifications when policies are executed:

```http
POST /webhooks/subscribe
Content-Type: application/json
Authorization: Bearer <token>

{
  "url": "https://your-server.com/dsg-webhooks",
  "events": ["policy.executed", "policy.recorded"],
  "policyIds": ["pol_payment_approval", "pol_task_assignment"]
}
```

**Webhook Payload:**

```json
{
  "event": "policy.executed",
  "ledgerId": "ledger_xyz789",
  "policyId": "pol_payment_approval",
  "decision": { ... },
  "proof": { ... },
  "timestamp": "2026-07-09T23:09:15.000Z"
}
```

---

## Examples

### Example 1: Simple Payment Approval

```bash
curl -X POST https://api.example.com/api/dsg-one/determinism/execute \
  -H "Authorization: Bearer $DSG_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "policyId": "pol_payment_approval",
    "context": {
      "amount": 5000,
      "supplier": "acme-corp",
      "tierApprovalLimit": 10000
    }
  }'
```

### Example 2: Task Assignment with Proof

```typescript
const client = new DSGClient({ token })

const result = await client.executePolicy({
  policyId: 'pol_task_assignment',
  context: { tasks, agents, constraints },
  options: { solverMode: 'ising-verify' }
})

// Record to audit trail
await client.recordEvidence(
  result.decision,
  result.proof,
  { ccvsLevel: 3 }
)

// Later: verify audit trail
const auditTrail = await client.verifyAuditTrail({
  startLedgerId: result.ledgerId,
  endLedgerId: 'last_known_id'
})

console.log('Integrity verified:', auditTrail.verified)
```

### Example 3: Benchmark Performance

```bash
curl -X POST https://api.example.com/api/dsg-one/ising/benchmark \
  -H "Authorization: Bearer $DSG_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problemSize": "medium",
    "solverModes": ["z3-only", "ising-verify"]
  }'
```

---

## Best Practices

1. **Always verify proofs** for critical decisions:
   ```typescript
   const proof = await client.getProof(ledgerId)
   assert(proof.verifiable, 'Proof must be verifiable')
   ```

2. **Implement exponential backoff** for retries:
   ```typescript
   let delay = 100
   for (let i = 0; i < 3; i++) {
     try { return await execute() }
     catch (e) { 
       if (e.code !== 'RATE_LIMIT') throw
       await sleep(delay)
       delay *= 2
     }
   }
   ```

3. **Record evidence immediately** after decisions:
   ```typescript
   const decision = await client.executePolicy(...)
   await client.recordEvidence(decision.decision, decision.proof)
   ```

4. **Audit trails regularly** for compliance:
   ```typescript
   const audit = await client.verifyAuditTrail({
     startLedgerId: monthStart,
     endLedgerId: monthEnd
   })
   assert(audit.verified, 'Audit trail integrity check failed')
   ```

---

## Support

- **Bugs**: [GitHub Issues](https://github.com/tdealer01-crypto/tdealer01-crypto-dsg-control-plane/issues)
- **Questions**: [GitHub Discussions](https://github.com/tdealer01-crypto/tdealer01-crypto-dsg-control-plane/discussions)
- **Email**: contact@dsg.pics

---

**Last Updated:** 2026-07-09 | **API Version:** 1.0 | **Status:** ✅ Production Ready
