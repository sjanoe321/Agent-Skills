# Common Queries — Cost and Use Oncology

## Overview
Ready-to-use query templates for common analysis scenarios against the Cost and Use tables. All queries target the `Analytics` database on `pr-vm-andb-01`.

---

## 1. Total Paid Amount by Health Plan and Line of Business

```sql
SELECT 
    [HealthPlan Overall],
    LineOfBusiness,
    YearOfService,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid,
    SUM(AllowedAmount) AS TotalAllowed,
    SUM(ClaimCount) AS TotalClaims
FROM DBO.AllPayers_OncoClaims_Final
GROUP BY [HealthPlan Overall], LineOfBusiness, YearOfService
ORDER BY [HealthPlan Overall], LineOfBusiness, YearOfService;
```

**How to interpret:** Compare TotalPaid across health plans proportional to their membership size. If one plan has disproportionately high TotalPaid relative to members, investigate whether it's a sicker population, higher unit costs, or utilization pattern. Expected: Medicare lines will have higher per-member costs than Commercial. RedFlag: UniqueMembers = 0 but TotalPaid > 0 suggests data issue.

---

## 2. PMPM (Per Member Per Month) by Health Plan

```sql
SELECT 
    c.[HealthPlan Overall],
    c.YearOfService,
    c.MonthOfService,
    SUM(c.PaidAmount) AS TotalPaid,
    SUM(m.membership) AS TotalMembership,
    CASE WHEN SUM(m.membership) > 0 
         THEN SUM(c.PaidAmount) / SUM(m.membership) 
         ELSE 0 END AS PMPM
FROM DBO.AllPayers_OncoClaims_Final c
LEFT JOIN DBO.AllPayers_OncoMem m 
    ON c.membershipkey = m.membershipkey
GROUP BY c.[HealthPlan Overall], c.YearOfService, c.MonthOfService
ORDER BY c.[HealthPlan Overall], c.YearOfService, c.MonthOfService;
```

**Note:** The `membershipkey` is the primary join key between claims and membership.

**How to interpret:** PMPM is the standard normalization metric for comparing cost across plans with different membership sizes. Oncology PMPM typically ranges $50-$200+ depending on LOB and cancer mix. A sudden spike in a single month may indicate a high-cost case or data lag. Compare month-over-month trends, not single months in isolation.

---

## 3. VBI Market Share vs Benchmark

```sql
SELECT 
    [HealthPlan Overall],
    VBIGroup,
    ConditionCategory,
    LineOfBusiness,
    COUNT(DISTINCT CASE WHEN DenominatorCases IS NOT NULL THEN DenominatorCases END) AS DenominatorMembers,
    COUNT(DISTINCT CASE WHEN Cases IS NOT NULL THEN Cases END) AS NonPreferredMembers,
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN Cases IS NOT NULL THEN Cases END) AS FLOAT) /
        NULLIF(COUNT(DISTINCT CASE WHEN DenominatorCases IS NOT NULL THEN DenominatorCases END), 0),
    2) AS ActualMarketShare,
    MAX(BM_MarketShare) AS BenchmarkMarketShare
FROM DBO.AllPayers_OncoClaims
WHERE VBIGroup IS NOT NULL
    AND VBIGroup != 'Checkpoint Inhibitor'  -- CPI uses different denominator logic
GROUP BY [HealthPlan Overall], VBIGroup, ConditionCategory, LineOfBusiness
HAVING COUNT(DISTINCT CASE WHEN DenominatorCases IS NOT NULL THEN DenominatorCases END) > 0
ORDER BY VBIGroup, [HealthPlan Overall];
```

**Note:** Use the staging table (`AllPayers_OncoClaims`) for VBI metric queries since DenominatorCases/Cases/Spend columns are excluded from the final table.

**How to interpret:** ActualMarketShare > BenchmarkMarketShare means the plan uses more non-preferred drugs than the benchmark population. Larger gaps indicate greater savings potential. If DenominatorMembers is very small (<10), the market share is unreliable — focus on groups with meaningful volume. CPI is excluded here because it uses a different denominator logic (see Query 5).

---

## 4. Active Treatment Patients by Condition Category

```sql
SELECT 
    [HealthPlan Overall],
    ConditionCategory,
    YearOfService,
    COUNT(DISTINCT MemberID) AS ActivePatients,
    SUM(PaidAmount) AS TotalPaid,
    SUM(PaidAmount) / NULLIF(COUNT(DISTINCT MemberID), 0) AS PaidPerPatient
FROM DBO.AllPayers_OncoClaims_Final
WHERE ActiveTreatment = 1
GROUP BY [HealthPlan Overall], ConditionCategory, YearOfService
ORDER BY TotalPaid DESC;
```

**How to interpret:** PaidPerPatient varies dramatically by condition — breast cancer may be $30K-$80K/year while lung cancer can exceed $100K. ActiveTreatment = 1 filters to patients currently receiving therapy, excluding surveillance-only patients. Comparing ActivePatients YoY shows whether the treated population is growing. A rising PaidPerPatient with stable patient counts suggests drug mix or unit cost inflation.

---

## 5. CPI Overuse Analysis

```sql
-- CPI overuse rate by health plan
SELECT 
    [HealthPlan Overall],
    YearOfService,
    COUNT(DISTINCT CASE WHEN DenominatorCases_CPI IS NOT NULL THEN DenominatorCases_CPI END) AS CPI_DenominatorMembers,
    COUNT(DISTINCT CASE WHEN Cases_CPI IS NOT NULL THEN Cases_CPI END) AS CPI_OveruseMembers,
    SUM(CASE WHEN Spend_CPI IS NOT NULL THEN CAST(Spend_CPI AS FLOAT) ELSE 0 END) AS CPI_OveruseSpend,
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN Cases_CPI IS NOT NULL THEN Cases_CPI END) AS FLOAT) /
        NULLIF(COUNT(DISTINCT CASE WHEN DenominatorCases_CPI IS NOT NULL THEN DenominatorCases_CPI END), 0),
    2) AS CPI_OveruseRate
FROM DBO.AllPayers_OncoClaims
WHERE VBIGroup = 'Checkpoint Inhibitor'
GROUP BY [HealthPlan Overall], YearOfService
ORDER BY [HealthPlan Overall], YearOfService;
```

**Note:** CPI uses PaidAmount as denominator (not MemberID count) — this is a unique calculation pattern.

**How to interpret:** CPI_OveruseRate represents the proportion of checkpoint inhibitor patients receiving therapy outside recommended guidelines. A rate above 15-20% warrants clinical review. CPI_OveruseSpend quantifies the financial impact. Watch for YoY trends — rising overuse rates may indicate new off-label use patterns or expanded indications not yet reflected in benchmarks.

---

## 6. MGF Short vs Long Acting Comparison

```sql
SELECT 
    [HealthPlan Overall],
    VBIGroup,  -- 'Short-Acting MGF' or 'Long-Acting MGF'
    YearOfService,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid,
    SUM(AllowedAmount) AS TotalAllowed,
    COUNT(DISTINCT CASE WHEN ActiveTreatment = 1 THEN MemberID END) AS ActiveTreatmentMembers
FROM DBO.AllPayers_OncoClaims_Final
WHERE VBIGroup IN ('Short-Acting MGF', 'Long-Acting MGF')
GROUP BY [HealthPlan Overall], VBIGroup, YearOfService
ORDER BY [HealthPlan Overall], VBIGroup;
```

**How to interpret:** Short-Acting MGF (filgrastim/biosimilars) is significantly cheaper than Long-Acting MGF (pegfilgrastim). A high ratio of Long-Acting to Short-Acting usage suggests savings opportunity through formulary management. Compare ActiveTreatmentMembers between the two — some clinical scenarios genuinely require long-acting. Industry trend is toward short-acting biosimilar MGF adoption.

---

## 7. VBD Drug Spend Analysis

```sql
SELECT 
    [HealthPlan Overall],
    ServiceDetail,
    YearOfService,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid,
    SUM(AllowedAmount) AS TotalAllowed,
    SUM(ClaimCount) AS TotalClaims
FROM DBO.AllPayers_OncoClaims_Final
WHERE VBD_Group = 'VBD'
GROUP BY [HealthPlan Overall], ServiceDetail, YearOfService
ORDER BY TotalPaid DESC;
```

**How to interpret:** VBD (Value-Based Drug) spend shows which specific drugs drive the most cost within the value-based program. ServiceDetail gives the drug name. Look for drugs where TotalPaid is high but UniqueMembers is low — these are high per-patient-cost drugs. Compare TotalPaid/UniqueMembers across drugs to identify unit cost outliers.

---

## 8. Biosimilar Adoption Rate

```sql
SELECT 
    [HealthPlan Overall],
    VBIGroup,  -- 'Bevacizumab', 'Rituximab', 'Trastuzumab'
    YearOfService,
    COUNT(DISTINCT MemberID) AS TotalMembers,
    COUNT(DISTINCT CASE WHEN IsPreferred = 'Yes' THEN MemberID END) AS BiosimilarMembers,
    COUNT(DISTINCT CASE WHEN IsPreferred = 'No' THEN MemberID END) AS OriginatorMembers,
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN IsPreferred = 'Yes' THEN MemberID END) AS FLOAT) /
        NULLIF(COUNT(DISTINCT MemberID), 0),
    2) AS BiosimilarRate
FROM DBO.AllPayers_OncoClaims_Final
WHERE [VBI Grouping] = 'Biosimilars'
GROUP BY [HealthPlan Overall], VBIGroup, YearOfService
ORDER BY [HealthPlan Overall], VBIGroup;
```

**How to interpret:** BiosimilarRate should be trending upward over time as biosimilar adoption increases. Industry benchmarks for mature markets (Bevacizumab, Rituximab) are 70-90% biosimilar. Plans below 50% have significant conversion opportunity. OriginatorMembers × (originator cost - biosimilar cost) approximates the savings potential. Trastuzumab biosimilar adoption typically lags the others.

---

## 9. Top Providers by Paid Amount

```sql
SELECT TOP 20
    [HealthPlan Overall],
    ServicingGroupName,
    ServicingGroupTIN,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid,
    SUM(ClaimCount) AS TotalClaims
FROM DBO.AllPayers_OncoClaims_Final
WHERE ServicingGroupName IS NOT NULL AND ServicingGroupName != ''
GROUP BY [HealthPlan Overall], ServicingGroupName, ServicingGroupTIN
ORDER BY TotalPaid DESC;
```

**How to interpret:** The top 20 providers typically account for 60-80% of total oncology spend. Calculate TotalPaid/UniqueMembers to compare cost-per-patient across providers — variation suggests different treatment patterns or case mix. Providers with very high TotalClaims relative to UniqueMembers may have higher utilization intensity. Use this as a starting point for provider-level deep dives.

---

## 10. Service Category Breakdown

```sql
SELECT 
    [HealthPlan Overall],
    ServiceLine,
    ServiceClass,
    ServiceCategory,
    YearOfService,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid,
    SUM(AllowedAmount) AS TotalAllowed
FROM DBO.AllPayers_OncoClaims_Final
WHERE ServiceCategory IS NOT NULL
GROUP BY [HealthPlan Overall], ServiceLine, ServiceClass, ServiceCategory, YearOfService
ORDER BY TotalPaid DESC;
```

**How to interpret:** ServiceLine → ServiceClass → ServiceCategory provides a hierarchy from broad to specific. Drug spend typically dominates (60-70% of total), followed by facility and professional fees. Compare the ServiceCategory mix across health plans — significant differences suggest different site-of-care patterns or benefit designs. Note that ServiceCategory may be NULL for some CountyCare claims (enriched post-union).

---

## 11. Membership Trend by Condition Group

```sql
SELECT 
    [HealthPlan Overall],
    conditiongroup,
    yearofservice,
    monthofservice,
    SUM(membership) AS TotalMembership,
    SUM(patients) AS TotalPatients
FROM DBO.AllPayers_OncoMem
GROUP BY [HealthPlan Overall], conditiongroup, yearofservice, monthofservice
ORDER BY [HealthPlan Overall], conditiongroup, yearofservice, monthofservice;
```

**How to interpret:** TotalMembership is the denominator for PMPM calculations. TotalPatients shows how many members in each condition group had oncology claims. A rising TotalPatients with flat TotalMembership indicates increasing cancer prevalence or improved diagnosis. Sudden membership drops may indicate contract changes or data feed issues rather than actual population changes.

---

## 12. VBI Grouping Summary (for BI Report)

```sql
SELECT 
    [HealthPlan Overall],
    [VBI Grouping],
    VBIGroup,
    IsPreferred,
    YearOfService,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid
FROM DBO.AllPayers_OncoClaims_Final
WHERE [VBI Grouping] IS NOT NULL
GROUP BY [HealthPlan Overall], [VBI Grouping], VBIGroup, IsPreferred, YearOfService
ORDER BY [VBI Grouping], VBIGroup, [HealthPlan Overall];
```

**How to interpret:** This is the master view for VBI reporting. IsPreferred = 'Yes' means the patient used the preferred/benchmark drug; 'No' means non-preferred. The ratio of Preferred to total UniqueMembers gives the preferred utilization rate by VBI group. Use this to feed BI dashboards — compare across health plans to identify which plans lag in preferred drug adoption for each VBI grouping.

---

## 13. Savings Opportunity Calculator

```sql
-- Comprehensive savings opportunity across all VBI groups
-- Use the STAGING table (AllPayers_OncoClaims) — VBI metric columns are excluded from Final

SELECT 
    [HealthPlan Overall],
    VBIGroup,
    CASE 
        WHEN VBIGroup IN ('Bevacizumab','Rituximab','Trastuzumab') THEN 'Biosimilars'
        WHEN VBIGroup = 'Checkpoint Inhibitor' THEN 'Appropriate CPI Use'
        WHEN VBIGroup IN ('Long-Acting MGF','Short-Acting MGF') THEN 'MGF'
        WHEN VBIGroup IN ('Adcetris','Cyramza','Perjeta','Provenge') THEN 'Pathway Conversions'
        WHEN VBIGroup = 'ESA' THEN 'ESA'
        WHEN VBIGroup = 'High-Cost Antiemetic' THEN 'High Cost Anti Emetics'
        ELSE 'Same Efficacy Substitutions'
    END AS [VBI Category],
    COUNT(DISTINCT CASE WHEN DenominatorCases IS NOT NULL THEN DenominatorCases END) AS DenominatorMembers,
    COUNT(DISTINCT CASE WHEN Cases IS NOT NULL THEN Cases END) AS NonPreferredMembers,
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN Cases IS NOT NULL THEN Cases END) AS FLOAT) /
        NULLIF(COUNT(DISTINCT CASE WHEN DenominatorCases IS NOT NULL THEN DenominatorCases END), 0),
    2) AS ActualMarketShare,
    MAX(CAST(BM_MarketShare AS FLOAT)) AS BenchmarkMarketShare,
    SUM(CAST(ISNULL(Spend, '0') AS FLOAT)) AS NonPreferredSpend,
    SUM(CAST(ISNULL(AlternativeSpend, '0') AS FLOAT)) AS AlternativeSpend,
    SUM(CAST(ISNULL(Spend, '0') AS FLOAT)) - SUM(CAST(ISNULL(AlternativeSpend, '0') AS FLOAT)) AS SavingsOpportunity
FROM DBO.AllPayers_OncoClaims
WHERE VBIGroup IS NOT NULL
GROUP BY 
    [HealthPlan Overall],
    VBIGroup,
    CASE 
        WHEN VBIGroup IN ('Bevacizumab','Rituximab','Trastuzumab') THEN 'Biosimilars'
        WHEN VBIGroup = 'Checkpoint Inhibitor' THEN 'Appropriate CPI Use'
        WHEN VBIGroup IN ('Long-Acting MGF','Short-Acting MGF') THEN 'MGF'
        WHEN VBIGroup IN ('Adcetris','Cyramza','Perjeta','Provenge') THEN 'Pathway Conversions'
        WHEN VBIGroup = 'ESA' THEN 'ESA'
        WHEN VBIGroup = 'High-Cost Antiemetic' THEN 'High Cost Anti Emetics'
        ELSE 'Same Efficacy Substitutions'
    END
HAVING COUNT(DISTINCT CASE WHEN DenominatorCases IS NOT NULL THEN DenominatorCases END) >= 10
ORDER BY SavingsOpportunity DESC;
```

**How to interpret:** SavingsOpportunity = NonPreferredSpend - AlternativeSpend. This represents the theoretical maximum savings if all non-preferred patients switched to preferred alternatives. Realistic achievable savings are typically 30-60% of the theoretical max. Focus on rows where ActualMarketShare > BenchmarkMarketShare AND SavingsOpportunity > $100K for actionable recommendations. The HAVING >= 10 filter excludes groups with too few patients for reliable market share.

---

## 14. YoY Trend Analysis with Decomposition

```sql
-- Year-over-Year PMPM trend with volume and price components
WITH CurrentYear AS (
    SELECT 
        [HealthPlan Overall],
        LineOfBusiness,
        COUNT(DISTINCT MemberID) AS Patients,
        SUM(PaidAmount) AS TotalPaid,
        SUM(ClaimCount) AS TotalClaims,
        SUM(PaidAmount) / NULLIF(SUM(ClaimCount), 0) AS AvgCostPerClaim
    FROM DBO.AllPayers_OncoClaims_Final
    WHERE YearOfService = YEAR(GETDATE())
    GROUP BY [HealthPlan Overall], LineOfBusiness
),
PriorYear AS (
    SELECT 
        [HealthPlan Overall],
        LineOfBusiness,
        COUNT(DISTINCT MemberID) AS Patients,
        SUM(PaidAmount) AS TotalPaid,
        SUM(ClaimCount) AS TotalClaims,
        SUM(PaidAmount) / NULLIF(SUM(ClaimCount), 0) AS AvgCostPerClaim
    FROM DBO.AllPayers_OncoClaims_Final
    WHERE YearOfService = YEAR(GETDATE()) - 1
    GROUP BY [HealthPlan Overall], LineOfBusiness
)
SELECT 
    c.[HealthPlan Overall],
    c.LineOfBusiness,
    p.TotalPaid AS PriorYearPaid,
    c.TotalPaid AS CurrentYearPaid,
    ROUND((c.TotalPaid - p.TotalPaid) / NULLIF(p.TotalPaid, 0) * 100, 1) AS PaidGrowthPct,
    p.Patients AS PriorYearPatients,
    c.Patients AS CurrentYearPatients,
    ROUND((CAST(c.Patients AS FLOAT) - p.Patients) / NULLIF(p.Patients, 0) * 100, 1) AS PatientGrowthPct,
    p.AvgCostPerClaim AS PriorAvgCost,
    c.AvgCostPerClaim AS CurrentAvgCost,
    ROUND((c.AvgCostPerClaim - p.AvgCostPerClaim) / NULLIF(p.AvgCostPerClaim, 0) * 100, 1) AS CostPerClaimGrowthPct
FROM CurrentYear c
JOIN PriorYear p ON c.[HealthPlan Overall] = p.[HealthPlan Overall] AND c.LineOfBusiness = p.LineOfBusiness
ORDER BY PaidGrowthPct DESC;
```

**How to interpret:** Decompose PaidGrowthPct into PatientGrowthPct (volume) and CostPerClaimGrowthPct (price). If volume is flat but price is rising, investigate drug mix shifts. If volume is rising but price is flat, it's a membership/utilization change. YoY comparisons are more reliable than monthly trends due to seasonality. **Caveat:** Current year may have IBNR in recent months — compare only complete months.

---

## 15. Data Validation Suite

```sql
-- Comprehensive data validation checks — run before any analysis
-- Check 1: Row counts and freshness by health plan
SELECT 
    HealthPlan,
    COUNT(*) AS TotalRows,
    MIN(MonthOfService) AS EarliestMonth,
    MAX(MonthOfService) AS LatestMonth,
    MAX(MonthOfPayment) AS LatestPayment,
    COUNT(DISTINCT MemberID) AS UniqueMembers,
    SUM(PaidAmount) AS TotalPaid,
    SUM(CASE WHEN PaidAmount = 0 THEN 1 ELSE 0 END) AS ZeroPaidRows,
    SUM(CASE WHEN VBIGroup IS NOT NULL THEN 1 ELSE 0 END) AS VBIGroupedRows,
    SUM(CASE WHEN ConditionCategory IS NOT NULL THEN 1 ELSE 0 END) AS HasConditionCategory,
    SUM(CASE WHEN ServiceCategory IS NULL THEN 1 ELSE 0 END) AS MissingServiceCategory
FROM DBO.AllPayers_OncoClaims_Final
GROUP BY HealthPlan
ORDER BY HealthPlan;
```

**How to interpret:** Every health plan should have rows. Check that LatestMonth is recent (within 2-3 months). ZeroPaidRows > 20% suggests capitated claims or data issues. VBIGroupedRows should be 5-15% of total. MissingServiceCategory > 30% for CountyCare is expected (enriched post-union); for others it's a red flag.

---

## 16. Provider Variation Analysis

```sql
-- Identify provider-level variation in VBI market share
-- Providers with high non-preferred use vs plan average
SELECT 
    [HealthPlan Overall],
    ServicingGroupName,
    ServicingGroupTIN,
    COUNT(DISTINCT MemberID) AS UniquePatients,
    SUM(PaidAmount) AS TotalPaid,
    -- Biosimilar adoption for this provider
    COUNT(DISTINCT CASE WHEN [VBI Grouping] = 'Biosimilars' AND IsPreferred = 'No' THEN MemberID END) AS OriginatorPatients,
    COUNT(DISTINCT CASE WHEN [VBI Grouping] = 'Biosimilars' AND IsPreferred = 'Yes' THEN MemberID END) AS BiosimilarPatients,
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN [VBI Grouping] = 'Biosimilars' AND IsPreferred = 'Yes' THEN MemberID END) AS FLOAT) /
        NULLIF(COUNT(DISTINCT CASE WHEN [VBI Grouping] = 'Biosimilars' THEN MemberID END), 0),
    2) AS BiosimilarRate
FROM DBO.AllPayers_OncoClaims_Final
WHERE ServicingGroupName IS NOT NULL AND ServicingGroupName != ''
GROUP BY [HealthPlan Overall], ServicingGroupName, ServicingGroupTIN
HAVING COUNT(DISTINCT MemberID) >= 10  -- minimum patient volume for reliability
ORDER BY TotalPaid DESC;
```

**How to interpret:** Look for providers with BiosimilarRate significantly below the plan average — these are engagement targets. Providers with high TotalPaid and low BiosimilarRate represent the highest-impact intervention opportunity. Only include providers with >= 10 patients for statistical reliability.

---

## Tips for Querying

1. **Use the Final table for most BI queries** — it's aggregated and filtered. Use the staging table only when you need VBI metric columns (DenominatorCases, Cases, Spend, etc.) or individual claim lines.
2. **Always use [HealthPlan Overall]** for grouping across clients — raw HealthPlan has many variants (MOLINA-IL, MOLINA-MI, etc.).
3. **CAST VBI metric columns** — DenominatorCases, Cases, Spend, etc. are VARCHAR(500). Cast to FLOAT or DECIMAL for math.
4. **PlaceOfService filter** — For outpatient oncology analysis, exclude POS 21 and 23: `WHERE PlaceOfService_Derived NOT IN ('21','23')`.
5. **MonthOfService format** — Stored as YYYYMM integer/varchar (e.g., 202301). Not a date type.
6. **MemberID for DISTINCT counts** — Use `COUNT(DISTINCT MemberID)` for unique patient counts, not row counts.
7. **Always validate before analyzing** — Run the Data Validation Suite (Query 15) before any analysis. Never present numbers from incomplete data.
8. **Savings queries use the STAGING table** — The DenominatorCases, Cases, Spend, and BM_* columns are only in AllPayers_OncoClaims (staging), NOT in AllPayers_OncoClaims_Final.
9. **CAST VBI metrics before math** — `CAST(ISNULL(Spend, '0') AS FLOAT)` — these are VARCHAR(500) columns.
10. **IBNR warning** — Flag the most recent 2-3 MonthOfService periods as potentially incomplete in any trend analysis.
11. **Minimum sample sizes** — Don't calculate market share or rates with fewer than 10 patients in the denominator. Use `HAVING COUNT(DISTINCT ...) >= 10`.
12. **Annualize with care** — When projecting annual savings from partial-year data: `Annual = (YTD Value / Complete Months) × 12`. Exclude IBNR-affected months from the calculation.
