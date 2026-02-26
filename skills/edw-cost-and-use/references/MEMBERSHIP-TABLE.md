## AllPayers_OncoMem — Membership Table

### Overview

This table contains oncology membership data across all health plans, used to calculate PMPM (per member per month) and denominator metrics in the Cost & Use BI report. Created by UNION ALL of client-specific membership tables.

### Columns

| Column | Type | Source | Business Meaning |
|--------|------|--------|-----------------|
| HealthPlan Overall | VARCHAR | Derived | CASE: MOLINA variants → 'Molina'; CAREPLUS/COVENTRY/SIMPLY → 'Legacy'; else keep HealthPlan name |
| healthplan | VARCHAR | Client membership tables | Raw health plan name (MOLINA, CAREPLUS, COVENTRY, FLBLUE, COUNTYCARE, HIGHMARK, etc.) |
| lineofbusiness | VARCHAR | Client membership tables | Line of business (Commercial, Medicare Advantage, Medicaid, Individual, etc.) |
| sublineofbusiness | VARCHAR | Client membership tables | Sub-line of business |
| nchmarket | VARCHAR | Client membership tables | NCH market region (empty string for CC and FLB) |
| yearofservice | VARCHAR/INT | Client membership tables | Year of service |
| monthofservice | VARCHAR/INT | Client membership tables | Month of service (YYYYMM format) |
| quarterofservice | VARCHAR/INT | Client membership tables | Quarter of service |
| membership | NUMERIC | Client membership tables | Membership count |
| conditiongroup | VARCHAR | Client membership tables | Oncology condition group |
| patients | NUMERIC | Client membership tables | Patient count |
| Period | VARCHAR | Client membership tables | Reporting period (empty string for CC and FLB) |
| membershipkey | VARCHAR | Client membership tables | Links membership to claims — composite key for joining |

### Union Sources

| Source Table | Temp Table Origin | Health Plans | Special Filters |
|-------------|-------------------|-------------|----------------|
| DBO.MolinaOncoMembership | ##MembershipMolina | MOLINA, MOLINA-IL, MOLINA-MI, etc. | None |
| DBO.LegacyOncoMembership | ##MembershipLegacy_Onc | CAREPLUS, COVENTRY | `WHERE HEALTHPLAN != 'SIMPLY'` |
| DBO.CCOncoMembership | ##CareplusMembership_Onc | COUNTYCARE | `WHERE SubLineOfBusiness != 'Pending/Null'`; nchmarket='', Period='' |
| DBO.FLBOncoMembership | ##FLBOncoMembership | FLBLUE | nchmarket='', Period='' |
| DBO.hIGHMARK_MEM | (direct table) | HIGHMARK | nchmarket='', Period=''; uses UNION (not UNION ALL) |

### Post-Union Processing

1. **Delete NULL conditiongroup**: `DELETE FROM dbo.AllPayers_OncoMem WHERE conditiongroup IS NULL`
2. **Delete FLBLUE with NULL SubLineOfBusiness**: `DELETE FROM dbo.AllPayers_OncoMem WHERE healthplan IN ('FLBLUE') AND SubLineOfBusiness IS NULL`
3. **UpperCaseWords formatting**: LineOfBusiness and SubLineOfBusiness are title-cased via `dbo.UpperCaseWords()` UDF
4. **HealthPlan title-casing**: Only for CAREPLUS, COUNTYCARE, SIMPLY, COVENTRY
5. **membershipkey fix**: `REPLACE(membershipkey,'MedicareNAALL','MedicareALL')` for CAREPLUS and COVENTRY

### HealthPlan Overall Mapping

Applied identically in all UNION branches:

```sql
CASE 
  WHEN HealthPlan LIKE '%MOLINA%' THEN 'Molina'
  WHEN HealthPlan IN ('CAREPLUS','COVENTRY','SIMPLY') THEN 'Legacy'
  ELSE HealthPlan
END AS [HealthPlan Overall]
```

### Key Notes

- **Joining to Claims**: Use `membershipkey` to join AllPayers_OncoMem to AllPayers_OncoClaims or AllPayers_OncoClaims_Final.
- **conditiongroup**: All rows with NULL conditiongroup are deleted — every membership row has a valid oncology condition group.
- **Highmark uses UNION (not UNION ALL)**: This deduplicates Highmark membership rows, unlike other clients which use UNION ALL.
- **Period and nchmarket**: These fields are empty strings for CountyCare, FLBlue, and Highmark — do not filter on them for these clients.

---

## Analytical Usage Guide

### Membership vs Patients — Key Distinction

These are two fundamentally different measures:

| Measure | Column | What It Means | Use Case |
|---|---|---|---|
| **Membership** | `membership` | Member-months — the total number of enrolled member-months for a given period. One member enrolled for 12 months = 12 member-months. | **PMPM denominator.** Normalizes cost by population size. Always use for per-member cost calculations. |
| **Patients** | `patients` | Unique patients with the specific oncology condition in that period. One member with breast cancer appearing in January = 1 patient for that month. | **Prevalence/utilization rate denominator.** Use for condition-specific utilization metrics like "cost per patient" or "active treatment rate." |

**Why this matters:** If you divide total paid by `patients` instead of `membership`, you get "cost per patient" (higher number, useful for clinical analysis). If you divide by `membership`, you get PMPM (lower number, useful for financial/actuarial analysis). They answer different questions.

### PMPM Calculation Walkthrough

**Step 1: Get claims spend**
```sql
SELECT 
    membershipkey,
    SUM(PaidAmount) AS TotalPaid
FROM DBO.AllPayers_OncoClaims_Final
GROUP BY membershipkey
```

**Step 2: Get membership**
```sql
SELECT 
    membershipkey,
    SUM(membership) AS TotalMemberMonths,
    SUM(patients) AS TotalPatients
FROM DBO.AllPayers_OncoMem
GROUP BY membershipkey
```

**Step 3: Join and calculate**
```sql
SELECT 
    m.[HealthPlan Overall],
    m.lineofbusiness,
    m.conditiongroup,
    SUM(ISNULL(c.TotalPaid, 0)) AS TotalPaid,
    SUM(m.TotalMemberMonths) AS TotalMemberMonths,
    CASE WHEN SUM(m.TotalMemberMonths) > 0 
         THEN SUM(ISNULL(c.TotalPaid, 0)) / SUM(m.TotalMemberMonths) 
         ELSE 0 END AS PMPM,
    CASE WHEN SUM(m.TotalPatients) > 0 
         THEN SUM(ISNULL(c.TotalPaid, 0)) / SUM(m.TotalPatients) 
         ELSE 0 END AS CostPerPatient
FROM (
    SELECT [HealthPlan Overall], lineofbusiness, conditiongroup, membershipkey,
           SUM(membership) AS TotalMemberMonths, SUM(patients) AS TotalPatients
    FROM DBO.AllPayers_OncoMem
    GROUP BY [HealthPlan Overall], lineofbusiness, conditiongroup, membershipkey
) m
LEFT JOIN (
    SELECT membershipkey, SUM(PaidAmount) AS TotalPaid
    FROM DBO.AllPayers_OncoClaims_Final
    GROUP BY membershipkey
) c ON m.membershipkey = c.membershipkey
GROUP BY m.[HealthPlan Overall], m.lineofbusiness, m.conditiongroup
ORDER BY PMPM DESC;
```

**Important PMPM notes:**
- Always LEFT JOIN claims to membership (not inner join) — some membership segments may have zero claims, and that's valid (PMPM = $0)
- Always segment by LOB — mixing Medicare and Commercial membership inflates/deflates PMPM
- PMPM varies dramatically by conditiongroup — Lung Cancer PMPM >> Prostate Cancer PMPM (due to drug costs)

### Condition Group Segmentation

The `conditiongroup` field enables condition-specific analysis. Typical analytical approaches:

**Condition-level PMPM ranking:**
```sql
SELECT 
    conditiongroup,
    SUM(membership) AS TotalMemberMonths,
    -- Join to claims for PMPM
    -- Use this to identify which conditions drive the most cost per member
```

**Condition mix analysis:**
```sql
-- What proportion of total membership is each condition?
SELECT 
    conditiongroup,
    SUM(membership) AS MemberMonths,
    ROUND(SUM(membership) * 100.0 / SUM(SUM(membership)) OVER(), 2) AS PctOfTotal
FROM DBO.AllPayers_OncoMem
GROUP BY conditiongroup
ORDER BY MemberMonths DESC;
```

**Why it matters:** Condition mix shifts can explain PMPM changes. If the proportion of high-cost conditions (Lung Cancer, AML) increases, PMPM rises even without any per-patient cost increase. This is the "mix effect" in variance analysis.

### Active Patients Rate

```sql
-- Active patients as a proportion of total oncology membership
-- Higher rate = more patients actively in treatment = higher expected PMPM
SELECT 
    m.[HealthPlan Overall],
    m.conditiongroup,
    SUM(m.patients) AS TotalPatients,
    SUM(m.membership) AS TotalMemberMonths,
    ROUND(CAST(SUM(m.patients) AS FLOAT) / NULLIF(SUM(m.membership), 0) * 1000, 1) AS PatientsPerThousand
FROM DBO.AllPayers_OncoMem m
GROUP BY m.[HealthPlan Overall], m.conditiongroup
ORDER BY PatientsPerThousand DESC;
```

**How to interpret:** PatientsPerThousand = oncology prevalence rate per 1,000 member-months. Higher rates suggest more cancer patients per enrolled population. Compare across health plans to understand population differences. Medicare should have higher rates than Commercial (older population = more cancer).

### Membership Completeness Checks

Before using membership data, validate:

```sql
-- Check membership continuity (no gaps)
SELECT 
    [HealthPlan Overall],
    monthofservice,
    SUM(membership) AS TotalMembership,
    LAG(SUM(membership)) OVER (PARTITION BY [HealthPlan Overall] ORDER BY monthofservice) AS PriorMonthMembership,
    ROUND(
        (SUM(membership) - LAG(SUM(membership)) OVER (PARTITION BY [HealthPlan Overall] ORDER BY monthofservice)) * 100.0 /
        NULLIF(LAG(SUM(membership)) OVER (PARTITION BY [HealthPlan Overall] ORDER BY monthofservice), 0), 
    1) AS PctChange
FROM DBO.AllPayers_OncoMem
GROUP BY [HealthPlan Overall], monthofservice
ORDER BY [HealthPlan Overall], monthofservice;
```

**Red flags:**
- **PctChange > ±20%:** Sudden membership jump/drop — likely a data load issue, not real enrollment change
- **TotalMembership = 0 for any month:** Do NOT calculate PMPM for that month (division by zero → infinite PMPM)
- **Missing months:** Gaps in the monthofservice sequence mean incomplete data — flag and exclude
- **Expected ranges by client:**
  - Molina: Largest plan — expect highest membership counts
  - Legacy: Moderate — CarePlus + Coventry combined
  - FLBlue: Moderate to large
  - CountyCare: Smaller, Medicaid-focused
  - Highmark: Varies

### The membershipkey Join — Deep Dive

The `membershipkey` is a composite key that encodes multiple dimensions. Its exact composition varies by client but typically includes:
- HealthPlan
- LineOfBusiness  
- SubLineOfBusiness
- MonthOfService (or time period)
- ConditionGroup

**This means:** When you join claims to membership on `membershipkey`, you're joining at the intersection of plan + LOB + time + condition. This is correct for condition-specific PMPM but means a single claim (with one membershipkey) links to ONE membership segment.

**Common mistake:** Trying to calculate total oncology PMPM by summing PaidAmount across all membershipkeys and dividing by total membership across all membershipkeys can double-count if a member appears in multiple conditiongroups. For total PMPM, aggregate membership to the plan+LOB+month level first (deduplicating conditiongroup).
