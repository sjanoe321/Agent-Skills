# Analytical Frameworks — Cost & Use Analysis

## Purpose

This document provides the analytical methodology, workflows, and presentation frameworks for conducting Cost & Use oncology analysis. It guides the agent on *how* to approach analysis questions, *what* to validate before interpreting, and *how* to present findings to different stakeholders.

---

## Structuring a Cost & Use Analysis

### Step-by-Step Methodology

**Step 1: Define Scope**

- Which health plans? (All, or specific HealthPlan Overall)
- Which time period? (YTD, rolling 12, specific quarters)
- Which LOB? (Medicare Advantage, Medicaid, Commercial/Marketplace — never mix without normalizing)
- Which service focus? (All oncology, specific VBI group, specific condition)

**Step 2: Validate Data**

Before ANY analysis, run validation checks (see Data Validation Checklist below). Never present numbers from incomplete or questionable data.

**Step 3: Segment**

Always segment before aggregating:

- By HealthPlan Overall (Molina, Legacy, FLBlue, CountyCare, Highmark)
- By LineOfBusiness (Medicare, Medicaid, Marketplace)
- By ConditionCategory (for condition-specific analysis)
- By VBI Grouping (for drug cost management analysis)

**Step 4: Calculate Core Metrics**

- PMPM (total and condition-specific)
- Utilization rates (claims/1K, patients/1K)
- Market share (for VBI groups)
- Savings opportunity (actual vs benchmark)

**Step 5: Benchmark**

Compare against:

- Internal benchmarks (prior period, other health plans)
- External benchmarks (BM_MarketShare from benchmark table)
- Expected ranges (see Data Validation Checklist)

**Step 6: Identify Drivers**

When a metric is out of range or trending:

- Is it volume (more patients/claims)?
- Is it price (higher cost per service)?
- Is it mix (shift toward more expensive drugs/conditions)?
- Is it a data quality issue?

**Step 7: Quantify Opportunity**

For every finding, calculate the dollar impact:

- Savings opportunity = (Actual - Benchmark) × relevant spend
- Annual run rate = monthly impact × 12
- Per-member impact = opportunity / affected membership

**Step 8: Present**

Frame findings for the audience (see Stakeholder Views below). Always include:

- What changed / what was found
- Why it matters (clinical + financial)
- How big is the impact ($)
- What action is recommended

---

## Stakeholder-Specific Views

### Clinical Operations (Medical Director, Clinical Pharmacy)

**What they care about:**

- Drug utilization patterns (are patients on the right drugs?)
- Pathway adherence (are treatment protocols being followed?)
- CPI overuse rates (are oncologists switching immunotherapy inappropriately?)
- Biosimilar adoption (are providers using biosimilars when available?)
- Provider variation (which practices are outliers?)

**How to present:**

- Lead with clinical metrics (market share, pathway adherence rate)
- Show provider-level variation
- Highlight specific drugs/conditions where intervention could improve care
- Use clinical language: "treatment pathways," "evidence-based alternatives," "therapeutic interchange"

**Key queries to run:**

- VBI Market Share vs Benchmark (by VBI group and condition)
- CPI Overuse Analysis (by health plan and provider)
- Biosimilar Adoption Rate (trending over time)
- Provider variation analysis (TIN-level market share comparison)

### Finance (CFO, Actuaries, Budget Analysts)

**What they care about:**

- Total oncology spend and PMPM trend
- Budget variance (actual vs expected)
- Savings opportunity quantification ($)
- Cost drivers (volume vs price vs mix)
- Projected run rate

**How to present:**

- Lead with PMPM and dollar totals
- Show YoY trend with decomposition
- Quantify every opportunity in annual dollars
- Segment by LOB (each has different budget implications)
- Include caveats: IBNR, data completeness, payment lag

**Key queries to run:**

- PMPM by health plan and LOB (trending)
- Total paid by service category
- Savings opportunity calculator
- YoY trend decomposition
- VBD drug spend analysis

### Network Management (Provider Relations, Contracting)

**What they care about:**

- Provider-level cost variation
- TIN-level drug utilization patterns
- High-cost outlier identification
- Contracting opportunities (which providers are expensive?)

**How to present:**

- Show provider rankings by total paid, PMPM, or market share
- Identify outliers (>2 standard deviations from mean)
- Compare provider performance to plan average and benchmark
- Highlight specific providers where engagement could yield savings

**Key queries to run:**

- Top providers by paid amount
- Provider-level VBI market share
- Provider cost per patient comparison
- TIN-level biosimilar adoption rates

### Executive (CEO, VP Medical Economics, Board)

**What they care about:**

- Summary: are we spending more or less than expected?
- Headline savings opportunity (total $)
- Trend direction (improving or deteriorating?)
- Key risks and recommended actions

**How to present:**

- Executive summary format (see template below)
- 3-5 bullet points max for key findings
- One chart showing trend
- Total savings opportunity in annualized dollars
- Clear action items

---

## Data Validation Checklist

Run these checks BEFORE any analysis. If any fail, investigate before proceeding.

### Completeness Checks

| Check | Query Approach | Expected Result | Red Flag |
|---|---|---|---|
| Row count by health plan | GROUP BY HealthPlan Overall, COUNT(*) | Proportional to membership | A client has 0 rows or <100 rows |
| Membership by month | GROUP BY monthofservice, SUM(membership) | Consistent month-to-month | >20% drop in recent months |
| MonthOfService coverage | MIN/MAX MonthOfService | Continuous from 202301 to recent | Gaps in month sequence |
| MonthOfPayment freshness | MAX(MonthOfPayment) per HealthPlan | Within 1-2 months of current date | >3 months stale |
| VBIGroup coverage | COUNT(*) WHERE VBIGroup IS NOT NULL | 5-15% of total claims have a VBI group | 0% or >50% suggests mapping issues |
| ConditionCategory coverage | COUNT(*) WHERE ConditionCategory IS NOT NULL | Most claims should have one | >30% NULL suggests lookup failures |
| PaidAmount sanity | SUM(PaidAmount) by HealthPlan per month | Stable month-to-month per plan | Sudden 50%+ increase or drop |

### Data Quality Checks per Client

| Client | Known Issue | How to Check | Mitigation |
|---|---|---|---|
| CountyCare | Many empty-string columns (TIN, NPI, AccountType) | COUNT(*) WHERE ServicingGroupTIN = '' | Don't use these columns for CC analysis |
| CountyCare | ProcedureCode_Derived may be empty or comma-separated | WHERE ProcedureCode_Derived LIKE '%,%' OR ProcedureCode_Derived = '' | These get enriched post-union but some may remain |
| FLBlue | TIN/GroupName populated post-union from EDW | COUNT(*) WHERE ServicingGroupTIN = '' AND HealthPlan = 'FLBLUE' | Some may still be empty after enrichment |
| Legacy | SIMPLY excluded from membership but may appear in claims | COUNT(*) WHERE HealthPlan = 'SIMPLY' | Excluded from final table; ignore in analysis |
| Highmark | Claims table name is placeholder | Check if Highmark claims actually exist | May have 0 claims rows |
| All | Recent months IBNR | Compare paid amounts for same month across successive data pulls | Flag last 2-3 months as "IBNR-affected" in any trend analysis |

### Sanity Check Ranges

| Metric | Typical Range | Context |
|---|---|---|
| Oncology PMPM | $50-$300 | Varies widely by LOB and plan. Medicare higher. |
| Active Treatment Rate | 10-30% of oncology members | Proportion with ActiveTreatment=1 |
| Biosimilar Market Share | 30-70% (trending upward) | Depends on drug class and market maturity |
| CPI Overuse Rate | 5-15% | Proportion of CPI patients who switched agents |
| Average oncology claim paid | $500-$5,000 | Per claim line (drug infusion visit) |
| VBIGroup assignment rate | 5-15% of total claims | Only injectable oncology drugs get VBI groups |

---

## Variance Analysis Framework

When asked "why did PMPM increase?" or "what changed?", decompose systematically:

### Volume-Price-Mix Decomposition

1. **Volume Change:** Did the number of claims or patients increase?
   - `Claims/1K this period vs prior period`
   - `Unique patients this period vs prior period`
   - If volume increased: new members? sicker population? increased screening?

2. **Price Change:** Did the cost per claim increase?
   - `Average PaidAmount per claim this period vs prior`
   - If price increased: new expensive drugs? contract rate changes? shift from generic to brand?

3. **Mix Change:** Did the distribution of services shift?
   - `Proportion of spend by ServiceCategory this period vs prior`
   - `Proportion of patients by ConditionCategory this period vs prior`
   - If mix shifted: more complex cancers? shift toward immunotherapy? VBI group distribution change?

### Single-Factor Analysis Template

```
Finding: [Metric] changed by [X%] from [Period A] to [Period B]
Volume Effect: [+/-X%] driven by [explanation]
Price Effect: [+/-X%] driven by [explanation]
Mix Effect: [+/-X%] driven by [explanation]
Net: [X%] total change, primarily driven by [dominant factor]
Action: [recommendation]
```

---

## Executive Summary Template

Use this structure for presenting Cost & Use findings:

### Template

```
COST & USE ANALYSIS — [Health Plan / All Plans] — [Time Period]

HEADLINES
• Oncology PMPM is $[X], [up/down X%] vs prior year
• [Largest savings opportunity]: $[X]M annual opportunity in [VBI group]
• [Key trend]: [description of most important change]

KEY FINDINGS
1. [Finding with dollar impact]
2. [Finding with dollar impact]
3. [Finding with dollar impact]

SAVINGS OPPORTUNITIES
| Category | Current Market Share | Benchmark | Gap | Annual Savings Opportunity |
|---|---|---|---|---|
| [VBI Group 1] | X% | X% | X pts | $X |
| [VBI Group 2] | X% | X% | X pts | $X |
| Total | | | | $X |

RECOMMENDATIONS
1. [Specific action] — Expected impact: $[X]
2. [Specific action] — Expected impact: $[X]
3. [Specific action] — Expected impact: $[X]

DATA NOTES
• Analysis period: [dates]
• Last [N] months may be affected by IBNR (incomplete claims)
• [Any client-specific data quality notes]
```

---

## Red Flag Patterns

When analyzing data, watch for these patterns that indicate either a problem or an opportunity:

| Pattern | What It Means | Action |
|---|---|---|
| PMPM spike in single month | Possible high-cost patient, data load issue, or one-time event | Investigate: is it one member? Check for outlier PaidAmount values. |
| Market share suddenly drops | Possible clinical intervention success OR data issue | Verify: did a biosimilar initiative launch? Or did data mapping change? |
| Zero membership for a client/month | Data load failure | Do not calculate PMPM — results would be infinite/meaningless |
| VBIGroup = NULL for claims that should have one | VBI lookup table gap or ProcedureCode mapping issue | Check ProspectClient_MedOnc_VBI_CPT/NDC for the ProcedureCode |
| PaidAmount = $0 on many claims | Capitated claims, denied claims, or data issue | Filter on NoFFSPayment flags; segment capitated vs FFS |
| ConditionCategory = NULL on many claims | Lookup failure against Unv_ClaimLine / Unv_ConditionOnco | Check join quality; may need additional enrichment passes |
| One provider with >30% of total paid | Concentration risk; also could be a center of excellence | Verify: is this a major cancer center? Expected for their volume? |
| Active Treatment = 0 for claims with VBI drugs | Patient not flagged as active treatment but receiving cancer drugs | May be maintenance therapy or data classification issue |
| Benchmark market share = 0 or 1 | Edge case in benchmark data | Don't calculate savings for this cell; insufficient benchmark data |
| MonthOfPayment months ahead of MonthOfService | Advance payments or data error | Investigate; typically payment should be same or later than service |

---

## Analysis Cheat Sheet

| Question | Approach | Key Table | Key Columns |
|---|---|---|---|
| "How much are we spending on oncology?" | Total PaidAmount, segment by HealthPlan/LOB | Final | PaidAmount, HealthPlan Overall, LOB |
| "What's our oncology PMPM?" | PaidAmount / membership, segment by LOB | Final + OncoMem | PaidAmount, membership, membershipkey |
| "Where are the savings opportunities?" | Market share vs benchmark for each VBI group | Staging (OncoClaims) | VBIGroup, DenominatorCases, Cases, Spend, BM_MarketShare |
| "Are we adopting biosimilars?" | Biosimilar rate by drug class over time | Final | VBI Grouping='Biosimilars', IsPreferred, YearOfService |
| "Is CPI overuse a problem?" | AdditionalCPI rate and spend | Staging | VBIGroup='Checkpoint Inhibitor', Cases_CPI, Spend_CPI, DenominatorCases_CPI |
| "Which providers are most expensive?" | Total paid by TIN, compare to peers | Final | ServicingGroupTIN, ServicingGroupName, PaidAmount |
| "Why did PMPM increase?" | Volume/Price/Mix decomposition | Final | PaidAmount, ClaimCount, MemberID, ServiceCategory |
| "What's the total savings opportunity?" | Sum all VBI group opportunities | Staging | All VBI metric columns + BM_MarketShare |
