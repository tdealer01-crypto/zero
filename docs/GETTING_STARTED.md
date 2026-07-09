# Getting Started with DSG

**5-minute setup guide for developers.**

---

## What You'll Build

A policy-governed AI agent that:
- ✅ Makes reproducible, auditable decisions
- ✅ Verifies solutions with formal proofs (Z3)
- ✅ Records complete evidence trails
- ✅ Survives 2+ year compliance audits

---

## Prerequisites

- **Node.js** 18+ or 20+
- **npm** or **pnpm**
- **Supabase** account (free tier works)
- **Vercel** account (optional, for deployment)

---

## Step 1: Clone & Install (2 min)

```bash
# Clone
git clone https://github.com/tdealer01-crypto/tdealer01-crypto-dsg-control-plane.git
cd tdealer01-crypto-dsg-control-plane

# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local
```

---

## Step 2: Configure Supabase (2 min)

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Create a project (or use existing)
3. Copy these from **Settings → API**:
   - `NEXT_PUBLIC_SUPABASE_URL` → Project URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` → `anon` public key
   - `SUPABASE_SERVICE_ROLE_KEY` → `service_role` secret key

4. Add to `.env.local`:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx...
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...
```

5. Run migrations:
```bash
npx supabase link --project-ref xxx
npx supabase db push
```

---

## Step 3: Run Locally (1 min)

```bash
npm run dev
```

Open [http://localhost:3000/dashboard](http://localhost:3000/dashboard)

---

## Step 4: Test (Optional, but recommended)

```bash
# Run all tests
npm test

# Run specific test file
npm test -- dsg-one-ising-llm-verifier.test.ts

# Run with coverage
npm test -- --coverage
```

Expected: **3091 tests passing** ✅

---

## Next: Your First Policy Decision

### Example 1: Simple Decision Gate

```typescript
import { analyzePolicyWithZ3 } from '@/lib/dsg/multi-agent/z3-constraint-solver'

// Define a policy: "Only approve payments < $10k from tier-1 suppliers"
const policy = {
  rules: [
    { type: 'max_amount', value: 10000 },
    { type: 'supplier_tier', value: 'tier-1' }
  ]
}

// Run the decision through DSG
const decision = await analyzePolicyWithZ3({
  context: { amount: 5000, supplier: 'acme-corp' },
  policy,
  options: { timeout: 5000 }
})

console.log(decision)
// Output: { approved: true, proof: 'sha256:abc123...', timestamp: '2026-07-09T...' }
```

### Example 2: Task Assignment

```typescript
import { solveTaskAssignmentConstraints } from '@/lib/dsg/multi-agent/z3-constraint-solver'

const tasks = [
  { id: 'task-1', complexity: 8, duration: 4 },
  { id: 'task-2', complexity: 5, duration: 3 }
]

const agents = [
  { id: 'agent-a', capacity: 10, skills: ['high-complexity'] },
  { id: 'agent-b', capacity: 8, skills: ['fast-turnaround'] }
]

const assignment = await solveTaskAssignmentConstraints(tasks, agents, {
  timeout: 5000
})

console.log(assignment)
// Output: { assignments: [...], proof: 'sha256:xyz789...', valid: true }
```

---

## Environment Variables (All Optional)

| Variable | Purpose | Example |
|----------|---------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Database connection | `https://xxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public auth | `eyJ...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin access | `eyJ...` |
| `NVIDIA_LLM_VERIFIER_MODE` | Enable advisory LLM | `advisory` |
| `NVIDIA_API_KEY` | NVIDIA API token | `nvapi-xxx` |
| `STRIPE_SECRET_KEY` | Stripe billing | `sk_live_xxx` |
| `NEXTAUTH_SECRET` | Session encryption | Auto-generated |

---

## File Structure

```
/lib
  /dsg                        # Core DSG engine
    /multi-agent
      z3-constraint-solver.ts # Deterministic solver
    /agent-*                  # Policy execution modules
    determinism-engine.ts     # Proof generation
    merkle-ledger.ts          # Audit trail
  
  /dsg-one                    # NVIDIA Ising integration
    ising-llm-verifier.ts     # LLM advisory layer
    ising-benchmark.ts        # Performance testing

/app
  /dashboard                  # Evidence & governance UI
  /api/dsg-one/*             # DSG execution endpoints

/tests
  dsg-one-*.test.ts          # Test suite (3091 tests)

/docs
  ARCHITECTURE.md            # System design deep dive
  SECURITY.md                # Security audit results
  VERIFICATION.md            # Z3 formal proof guide
  COMPLIANCE.md              # CCVS evidence chain
```

---

## Common Tasks

### Add a New Policy Rule

Edit `/lib/dsg/policy-definitions.ts`:

```typescript
export const policyRules = {
  max_transaction: {
    validator: (value: number, limit: number) => value <= limit,
    costFunction: 'linear'
  },
  require_approval: {
    validator: (approved: boolean) => approved === true,
    costFunction: 'boolean'
  }
}
```

### View Audit Trail

Navigate to [/dashboard/evidence](http://localhost:3000/dashboard/evidence):
- Filter by policy, date range, decision type
- Download proof artifacts (JSON, Markdown)
- Verify Merkle chain integrity

### Benchmark Solver Performance

```bash
npm run bench:ising
```

Generates reports in `/reports/ising-benchmark/` with latency, determinism, and solution quality metrics.

---

## Troubleshooting

### "Database connection failed"
- Check `NEXT_PUBLIC_SUPABASE_URL` is set correctly
- Verify service role key has admin permissions
- Run: `npx supabase db push` to sync migrations

### "Z3 solver timeout"
- Increase `timeout` option (default: 5000ms)
- Check problem complexity (> 500 variables may require Ising)
- Review constraints for redundancy

### "NVIDIA API unavailable"
- Set `NVIDIA_LLM_VERIFIER_MODE` to `advisory` (opt-in)
- LLM failures gracefully degrade (deterministic solver always decides)
- No external API needed for core DSG functionality

### "Tests timeout in CI"
- Some E2E tests require live Supabase connection
- Run `npm test -- --testTimeout=15000` for slower networks
- See `.github/workflows/ci.yml` for parallel job configuration

---

## Deploy to Vercel

1. **Push to GitHub**
```bash
git add . && git commit -m "Initial DSG setup"
git push origin main
```

2. **Import to Vercel**
   - Go to [vercel.com/import](https://vercel.com/import)
   - Select repository
   - Add environment variables (same as `.env.local`)
   - Click Deploy

3. **Verify**
   - Health check: `https://your-deployment.vercel.app/api/readiness`
   - Dashboard: `https://your-deployment.vercel.app/dashboard`

---

## Learn More

| Topic | Document | Read Time |
|-------|----------|-----------|
| **How DSG works** | [ARCHITECTURE.md](./ARCHITECTURE.md) | 15 min |
| **Formal verification** | [VERIFICATION.md](./VERIFICATION.md) | 20 min |
| **Security details** | [SECURITY.md](./SECURITY.md) | 10 min |
| **Compliance audits** | [COMPLIANCE.md](./COMPLIANCE.md) | 15 min |
| **API endpoints** | [API.md](./API.md) | 20 min |

---

## Get Help

- 📖 **GitHub Issues**: [Report bugs](https://github.com/tdealer01-crypto/tdealer01-crypto-dsg-control-plane/issues)
- 💬 **Discussions**: [Ask questions](https://github.com/tdealer01-crypto/tdealer01-crypto-dsg-control-plane/discussions)
- 📧 **Email**: contact@dsg.pics

---

## What's Next?

✅ **Just getting started?** Continue to [ARCHITECTURE.md](./ARCHITECTURE.md) for system design.

✅ **Want to run a policy?** See [API.md](./API.md) for endpoint reference.

✅ **Building integrations?** Check [Integrations.md](./INTEGRATIONS.md) for Stripe, Solana, Thai language.

✅ **Deploying to production?** Review [SECURITY.md](./SECURITY.md) + [COMPLIANCE.md](./COMPLIANCE.md).

---

**Status:** ✅ Production Ready | ✅ 3091 Tests Passing | ✅ Zero Critical Vulnerabilities

**Deploy confidently.** Every decision is auditable.
