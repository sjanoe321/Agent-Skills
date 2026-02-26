# Health Economics Concepts — Cost & Use Analysis

## Purpose

This document provides the health economics methodology and concepts a medical economics analyst needs to properly calculate, interpret, and present Cost & Use metrics. These are the "how to think about the numbers" beyond the raw SQL.

---

## PMPM (Per Member Per Month)

### Definition

PMPM = Total Paid Amount / Total Member Months

This is the foundational metric in health plan economics. It normalizes cost by membership size, making plans of different sizes comparable.

### Calculation Approaches

**Overall Oncology PMPM:**

```
PMPM = SUM(AllPayers_OncoClaims_Final.PaidAmount) / SUM(AllPayers_OncoMem.membership)
```

Join on `membershipkey`. This gives the total oncology cost per member per month.

**Condition-Specific PMPM:**

```
PMPM_condition = SUM(PaidAmount WHERE ConditionCategory = X) / SUM(membership WHERE conditiongroup = X)
```

Useful for identifying which cancers are driving cost growth.

**LOB-Specific PMPM:**

Always segment PMPM by LineOfBusiness (Medicare Advantage, Medicaid, Commercial/Individual). These populations have fundamentally different cost profiles:

- **Medicare Advantage:** Older population, higher cancer incidence, higher PMPM expected
- **Medicaid:** Younger, lower incidence but may have later-stage diagnoses
- **Commercial/Individual (Marketplace):** Working-age, moderate incidence

**Trend-Adjusted PMPM:**

Compare PMPM across time periods to identify cost trends. Always use same-month comparisons (Jan 2024 vs Jan 2023) to account for seasonality.

### Common Mistakes

- **Don't mix LOBs** when calculating PMPM — a 10% Medicare shift inflates PMPM even without true cost increase
- **Payment lag:** Use MonthOfService (not MonthOfPayment) for incurred PMPM to get a true picture. MonthOfPayment PMPM lags by 1-3 months.
- **Incomplete months:** The final table filters `MonthOfPayment <= current month - 1`. Recent MonthOfService periods may have incomplete paid claims (IBNR).

---

## Market Share

### Definition

Market Share = Non-Preferred Cases / Total Cases (DenominatorCases)

In the VBI context, "market share" means the proportion of patients using the non-preferred (usually more expensive) drug option.

### Interpretation

- **Lower is better** for substitution groups (Biosimilars, Same Efficacy Substitutions): lower market share = more patients on preferred (cheaper) alternative
- **For CPI:** Market share represents the overuse rate (proportion of CPI spend that is additional/switched CPI therapy)
- **Compare to benchmark:** `BM_MarketShare` from the benchmark table represents industry average. Your actual market share vs benchmark shows opportunity.

### Market Share Formula by VBI Category

| Category | Numerator (Cases) | Denominator | Better When |
|---|---|---|---|
| Same Efficacy Substitution | Patients on non-preferred drug | All patients using the drug class | Lower |
| Biosimilars | Patients on originator (brand) | All patients using the biologic | Lower |
| Pathway Conversions | Patients on active treatment using the drug | Active treatment patients | Depends on context |
| CPI Overuse | Additional CPI spend (switched agents) | Total CPI spend | Lower |
| MGF | Short/Long-Acting MGF patients | All MGF patients | Depends on strategy |

---

## Savings Opportunity Modeling

### Basic Savings Formula

```
Savings Opportunity = (Actual Market Share - Benchmark Market Share) × Total Spend in Category
```

### Substitution Savings

For biosimilars and same efficacy substitutions:

```
Avoidable Spend = Non-Preferred Spend × (1 - Benchmark Market Share / Actual Market Share)
```

Or more simply:

```
Avoidable Spend = Spend (non-preferred) - AlternativeSpend (preferred equivalent)
```

### The 10% Alternative Spend Rule

For pathway conversion groups (Adcetris, Cyramza, Perjeta, Provenge, High-Cost Antiemetic, Zepzelca):

```
AlternativeSpend = PaidAmount × (1 - 0.90) = PaidAmount × 0.10
```

This means the model assumes 90% of pathway conversion spend is avoidable through better clinical pathway adherence. The 10% represents the minimum expected spend even with perfect pathway adherence.

**Why 90%?** This is a clinical assumption that most pathway conversion drugs could be avoided with proper first-line treatment selection. It's aggressive — actual achievable savings are typically 30-50%.

### Biosimilar Savings Estimate

```
Potential Savings = Originator Spend × Biosimilar Discount Rate
```

Typical biosimilar discount rates:

- Bevacizumab biosimilars: 35-45% discount vs Avastin
- Rituximab biosimilars: 30-40% discount vs Rituxan
- Trastuzumab biosimilars: 30-45% discount vs Herceptin

### CPI Overuse Savings

```
CPI Avoidable Spend = Spend_CPI (where AdditionalCPI = 1)
```

This represents spend on CPI therapy for patients who switched agents without clinical justification.

---

## Utilization Metrics

### Claims per 1,000 Members

```
Claims/1K = (Total Claims / Total Member Months) × 1000
```

Normalizes claim volume by population size.

### Unique Patients per 1,000 Members

```
Patients/1K = (COUNT(DISTINCT MemberID) / Total Member Months) × 1000
```

Measures cancer prevalence/utilization rate.

### Average Cost per Episode

```
Cost/Episode = Total PaidAmount / COUNT(DISTINCT MemberID)
```

Episode = all services for one patient. Higher may indicate more complex cases or less efficient care.

### Average Cost per Claim

```
Cost/Claim = Total PaidAmount / ClaimCount
```

Reflects unit cost and intensity of services.

---

## Trend Analysis

### Year-over-Year (YoY) Comparison

```
YoY Growth = (Current Period PMPM - Prior Period PMPM) / Prior Period PMPM × 100
```

Always compare same calendar months to account for seasonality.

### Volume vs Price vs Mix Decomposition

When PMPM changes, decompose into three drivers:

1. **Volume:** Did more patients use services? (Claims/1K change)
2. **Price:** Did the cost per service change? (Cost/Claim change)
3. **Mix:** Did the proportion of expensive vs cheap services shift? (Service category distribution change)

```
PMPM Change ≈ Volume Effect + Price Effect + Mix Effect

Volume Effect = (New Claims/1K - Old Claims/1K) × Old Cost/Claim
Price Effect  = Old Claims/1K × (New Cost/Claim - Old Cost/Claim)
Mix Effect    = Residual (interaction of volume and price changes)
```

### Seasonality Considerations

- **Q1:** Often lower utilization (deductible resets in commercial plans)
- **Q4:** Higher utilization (members meeting out-of-pocket maximums, year-end care completion)
- **Cancer-specific:** Less seasonal than general medical, but still impacted by plan design

### IBNR (Incurred But Not Reported)

Recent service months may have incomplete claims data because:

- Claims take 30-90 days to process and appear in data
- The final table filters `MonthOfPayment <= current month - 1`
- **Rule of thumb:** MonthOfService within the last 2-3 months is likely incomplete. Flag it as "IBNR-affected" in any analysis.

### Run Rate Calculation

```
Annualized Run Rate = (YTD Paid / Months Elapsed) × 12
```

Use the most recent complete months (exclude IBNR-affected months).

---

## Cost Amount Types

### Allowed Amount

- **What:** The maximum amount the plan agrees to pay for a service (based on contract/fee schedule)
- **When to use:** Reflects the "sticker price" before member cost-sharing. Use for total cost of care analysis.

### Paid Amount

- **What:** The actual amount the plan paid to the provider (after deductibles, copays, coinsurance)
- **When to use:** Reflects plan liability. Use for financial analysis, budget, and PMPM calculations. **This is the primary metric for Cost & Use reporting.**

### Medicare Allowable (MCA_MedicareAllow, MCA_Paid)

- **What:** What Medicare would pay for the same service (used as a benchmark)
- **When to use:** MCA ratio analysis — compare plan paid to Medicare rates:

  ```
  MCA Ratio = PaidAmount / MCA_MedicareAllow
  ```

  - Ratio > 1.0: Plan pays more than Medicare
  - Ratio < 1.0: Plan pays less than Medicare
  - Used in network adequacy and contract negotiation analysis

### MedicareAllowableIncurredYear

- **What:** Medicare allowable amount using the fee schedule for the incurred year (not the payment year)
- **When to use:** For proper trend comparison (avoids fee schedule update distortion)

---

## Risk Type and Capitation

### Fee-for-Service (FFS) vs Capitated

- **FFS:** Provider is paid per service rendered. Each claim has a PaidAmount reflecting actual payment.
- **Capitated:** Provider receives a fixed per-member payment regardless of services. Claims may show $0 PaidAmount (Capitated_Claim flag).
- **Impact on analysis:**
  - Capitated claims should be EXCLUDED from paid amount analysis (they understate true cost)
  - Use `NoFFSPayment_Claim` and `NoFFSPayment_ClaimLine` flags to identify FFS vs capitated
  - For capitated populations, use AllowedAmount as a proxy for economic value

### RiskType

- Indicates the financial risk arrangement for the claim
- Important for segmenting FFS vs value-based care populations

---

## Benchmarking Methodology

### How BM_MarketShare Works

The benchmark comes from `ProspectClient_MedOnc_Benchmark_V13e` and represents industry-average non-preferred market share for a given:

- **VBI Group** (Metric = VBIGroup)
- **Cancer Group** (CancerGroup = ConditionCategory)
- **Line of Business** (normalized: Individual/Commercial → Marketplace, Medicare Advantage → Medicare)

### Interpreting Benchmark Comparison

```
Opportunity = Actual Market Share - Benchmark Market Share
```

- **Positive opportunity:** Your plan's non-preferred rate exceeds industry average → room for improvement
- **Negative/zero:** Already at or better than benchmark → maintain current performance
- **CPI benchmark capped at 1.0:** CPI overuse rate can't exceed 100% by definition

### Limitations

- Benchmarks are static (V13e version) — may not reflect latest market dynamics
- Benchmarks are national averages — regional variation exists
- Case-mix differences (patient severity, comorbidities) are not adjusted

---

## Key Economic Ratios

| Ratio | Formula | Use Case | Good Direction |
|---|---|---|---|
| PMPM | Paid / Member Months | Overall cost efficiency | Lower (cost containment) |
| Market Share | Non-Preferred Cases / Total Cases | Drug substitution opportunity | Lower |
| Biosimilar Rate | Biosimilar Patients / Total Biologic Patients | Biosimilar adoption | Higher |
| CPI Overuse Rate | Additional CPI Members / Total CPI Members | Immunotherapy efficiency | Lower |
| MCA Ratio | Paid / Medicare Allowable | Contract pricing | Closer to 1.0 |
| Active Treatment Rate | Active Patients / Total Patients | Utilization intensity | Context-dependent |
| JW Waste Rate | JW-flagged Claims / Total Drug Claims | Drug waste | Lower |
| Cost per Episode | Total Paid / Unique Members | Case intensity | Context-dependent |
