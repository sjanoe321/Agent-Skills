# CLAIMS-TABLE Reference

This reference doc covers every column in `DBO.AllPayers_OncoClaims` (staging) and `DBO.AllPayers_OncoClaims_Final` (aggregated final) tables used in the Cost & Use BI report.

## AllPayers_OncoClaims — Base Columns (from UNION)

These columns come from the UNION ALL of MolinaOncoClaims, LegacyOncoClaims, CCOncoClaims, FLBOncoClaims, and Highmark:

| Column | Type (approx) | Source | Business Meaning |
|--------|------|--------|-----------------|
| SourceTable | VARCHAR | Client proc | Identifies source system/table |
| DataSource | VARCHAR | Client proc | Data source identifier (empty for FLBlue) |
| HealthPlan | VARCHAR | Client proc | Health plan name (MOLINA, CAREPLUS, COVENTRY, FLBLUE, COUNTYCARE, etc.) |
| nchmarket | VARCHAR | Client proc | NCH market region (empty for CC/FLB) |
| YearOfService | INT/VARCHAR | Client proc | Year of service date |
| QuarterOfService | INT/VARCHAR | Client proc | Quarter of service date |
| MonthOfService | INT/VARCHAR | Client proc | Month of service (YYYYMM format) |
| DateOfService | DATE | Client proc | Actual date of service |
| MonthofPayment | VARCHAR | Client proc | Payment month (YYYYMM format) |
| MemberID | VARCHAR | Client proc | Member identifier |
| MemberAge | INT/VARCHAR | Client proc | Member age at time of service |
| ServicingGroupTIN | VARCHAR | Client proc | Provider group TIN (empty for CC/FLB initially; FLB enriched later) |
| ServicingGroupName | VARCHAR | Client proc | Provider group name |
| ServicingProviderName | VARCHAR | Client proc | Individual provider name (Legacy uses ServicingGroupName; CC uses CASE with ProviderName fallback) |
| ServicingProviderNPI | VARCHAR | Client proc | Provider NPI (empty for CC/FLB) |
| LineOfBusiness | VARCHAR | Client proc | Line of business (Commercial, Medicare Advantage, Medicaid, etc.) |
| SubLineOfBusiness | VARCHAR | Client proc | Sub-line of business |
| AccountType | VARCHAR | Client proc | Account type (empty for CC/FLB/Highmark) |
| ClaimNumber | VARCHAR | Client proc | Unique claim identifier |
| ClaimNumber_NoAdjRev | VARCHAR | Client proc | Claim number without adjustment/reversal suffix (empty for CC/FLB/Highmark) |
| ClaimLine | VARCHAR/INT | Client proc | Line number within claim |
| ClaimType_Derived | VARCHAR | Client proc | Derived claim type |
| ProcedureCode_Derived | VARCHAR | Client proc | CPT/HCPCS/NDC procedure code (CC falls back to CPTCODE) |
| ProcedureCodeType | VARCHAR | Client proc | Procedure code type (empty for CC/FLB/Highmark) |
| CPTDescription | VARCHAR | Client proc | CPT code description (CC uses CPTCodeDesc) |
| Modifier1 | VARCHAR | Client proc | Primary modifier |
| Modifier2 | VARCHAR | Client proc | Secondary modifier |
| DRGType | VARCHAR | Client proc | DRG type (empty for CC/FLB/Highmark) |
| AllowedUnits | NUMERIC | Client proc | Allowed units (FLB uses BilledUnits) |
| AllowedAmount | NUMERIC | Client proc | Allowed dollar amount (CC uses AllowedAmt) |
| PaidAmount | NUMERIC | Client proc | Paid dollar amount |
| MedicareAllowableIncurredYear | NUMERIC | Client proc | Medicare allowable for incurred year |
| AuthNumber | VARCHAR | Client proc | Authorization number |
| DX1 | VARCHAR | Client proc | Primary diagnosis code |
| DX2 | VARCHAR | Client proc | Secondary diagnosis code |
| ConditionGroup | VARCHAR | Client proc | Oncology condition group |
| ServiceLine | VARCHAR | Client proc | Service line classification |
| ServiceClass | VARCHAR | Client proc | Service class classification |
| ServiceCategory | VARCHAR | Client proc | Service category classification |
| ServiceType | VARCHAR | Client proc | Service type (empty for CC/FLB/Highmark) |
| ServiceDetail | VARCHAR | Client proc | Service detail / drug name |
| ScopeDetail | VARCHAR | Client proc | Scope detail (empty for CC/FLB/Highmark) |
| PlaceOfService_Derived | VARCHAR | Client proc | Place of service code (CC uses POS column) |
| Capitated_Claim | VARCHAR | Client proc | Whether claim is capitated (empty for FLB/Highmark) |
| RiskType | VARCHAR | Client proc | Risk type (empty for CC/FLB/Highmark) |
| Taxonomy_Derived | VARCHAR | Client proc | Provider taxonomy code (empty for CC/FLB/Highmark) |
| TaxonomyDesc_Derived | VARCHAR | Client proc | Taxonomy description (empty for CC/FLB/Highmark) |
| InScope | VARCHAR | Client proc | Whether claim is in scope |
| ServiceCodeDescription | VARCHAR | Client proc | Service code description |
| AdmitType_DERIVED | VARCHAR | Client proc | Admission type (empty for CC/FLB/Highmark) |
| claimnumberlinecpt | VARCHAR | Client proc | Concatenated claim+line+CPT key (empty for CC/FLB/Highmark) |
| memdos | VARCHAR | Client proc | CONCAT(MemberID, DateOfService) — CC/FLB compute dynamically |
| memmon | VARCHAR | Client proc | CONCAT(MemberID, MonthOfService) — CC/FLB compute dynamically |
| NDCNumber | VARCHAR | Client proc | NDC drug code (empty for CC/FLB/Highmark) |
| MCA_MedicareAllow | NUMERIC | Client proc | MCA Medicare allowable amount |
| MCA_Paid | NUMERIC | Client proc | MCA paid amount |
| ActiveTreatment | BIT/INT | Client proc | Whether patient is on active treatment |
| ModifierGroup_derived | VARCHAR | Client proc | Derived modifier group |
| POS_grouped | VARCHAR | Client proc | Grouped place of service |
| totalpaidprocedure | NUMERIC | Client proc | Total paid for the procedure |
| Period | VARCHAR | Client proc | Reporting period (empty for CC/FLB/Highmark) |
| membershipkey | VARCHAR | Client proc | Links claims to membership dimension |
| NoFFSPayment_Claim | VARCHAR | Client proc | FFS payment flag at claim level |
| NoFFSPayment_ClaimLine | VARCHAR | Client proc | FFS payment flag at claim line level |
| AdjustedConcat | VARCHAR | Client proc | Adjustment concatenation key |
| Paid_Flag | NUMERIC | Computed | `SUM(PaidAmount) OVER(PARTITION BY ServicingGroupName)` — total paid per provider group |
| Remark Code Line | VARCHAR(500) | Initially NULL | Populated later from Master_NDC_ClaimLine_PostPay |
| Auth Outcome | VARCHAR(500) | Initially NULL | Populated later from Master_NDC_ClaimLine_PostPay |
| ServiceSubCategory | VARCHAR(500) | Initially NULL | Populated later from CPT_Curr / NDC |
| Rowid | VARCHAR | Client proc | Row identifier linking to EDW.Fact.Unv_ClaimLine (CC casts to VARCHAR) |
| BillTypeCode | VARCHAR | Client proc | Bill type code |
| MedicarePart | VARCHAR | Client proc | Medicare part (A/B) |

## AllPayers_OncoClaims — ALTER TABLE Additions

These columns are added via ALTER TABLE and populated via UPDATE statements:

| Column | Type | Source | Business Meaning |
|--------|------|--------|-----------------|
| AdditionalCPI | VARCHAR(500) | Derived | 1 if member already had a CPI claim in a prior month with different ServiceDetail; 0 otherwise |
| ConditionCategory | VARCHAR(500) | EDW.Dim.Unv_ConditionOnco via Fact.Unv_ClaimLine | Oncology condition category (multi-pass fallback: Rowid+Claim+Line → Claim+Line+DX1 → Rowid → Rowid only → CountyCare-specific) |
| VBIGroup | VARCHAR(500) | ProspectClient_MedOnc_VBI_CPT/NDC then filtered | Value-Based Insurance drug group (Taxane, Checkpoint Inhibitor, MGF, VBD, etc.) |
| IsPreferred | VARCHAR(500) | ProspectClient_MedOnc_VBI_CPT/NDC | Yes/No preferred status |
| BudgetRollup | VARCHAR(500) | ProspectClient_MedOnc_VBI_CPT/NDC (ServiceDetail) | Budget rollup category |
| DenominatorCases | VARCHAR(500) | Derived CASE | MemberID for most VBI groups; PaidAmount for CPI |
| Cases | VARCHAR(500) | Derived CASE | MemberID when IsPreferred='No' for substitution groups; MemberID when ActiveTreatment=1 for pathway groups |
| Spend | VARCHAR(500) | Derived CASE | PaidAmount matching Cases logic |
| AlternativeCases | VARCHAR(500) | Derived CASE | MemberID when IsPreferred='Yes'; '0' for non-applicable groups |
| AlternativeSpend | VARCHAR(500) | Derived CASE | PaidAmount when IsPreferred='Yes'; PaidAmount*(1-0.90) for pathway groups; 0 for CPI |
| Cases_MGF_SL | VARCHAR(500) | Derived | MemberID when VBIGroup='Long-Acting MGF' |
| Spend_MGF_SL | VARCHAR(500) | Derived | PaidAmount when Long-Acting MGF, else 0 |
| AlternativeCases_MGF_SL | VARCHAR(500) | Derived | MemberID when VBIGroup='Short-Acting MGF' |
| AlternativeSpend_MGF_SL | VARCHAR(500) | Derived | PaidAmount when Short-Acting MGF, else 0 |
| AlternativeCases_CPI | VARCHAR(500) | Derived | Always 0 |
| AlternativeSpend_CPI | VARCHAR(500) | Derived | Always 0 |
| BM_DenominatorCases | VARCHAR(500) | ProspectClient_MedOnc_Benchmark_V13e | Benchmark denominator cases |
| BM_Cases | VARCHAR(500) | ProspectClient_MedOnc_Benchmark_V13e | Benchmark cases |
| BM_MarketShare | VARCHAR(500) | Derived | ROUND(BM_Cases/BM_DenominatorCases, 2); capped at 1.0 for CPI |
| DenominatorCases_agg | VARCHAR(500) | Derived | MemberID when ActiveTreatment=1 and POS not 21/23 |
| DenominatorCases_CPI | VARCHAR(500) | Derived | MemberID when VBIGroup='Checkpoint Inhibitor' and not YERVOY |
| Spend_vbd | VARCHAR(500) | Derived | PaidAmount for VBD drugs with ActiveTreatment=1 and POS not 21/23 |
| Cases_vbd | VARCHAR(500) | Derived | PaidAmount for VBD drugs with JW modifier and POS not 21/23 |
| Cases_CPI | VARCHAR(500) | Derived | MemberID when AdditionalCPI=1 and CPI group (not YERVOY) |
| Spend_CPI | VARCHAR(500) | Derived | PaidAmount when AdditionalCPI=1 and CPI group (not YERVOY), else 0 |
| Cases_MGF | VARCHAR(500) | Derived | MemberID when ActiveTreatment=1 and Short/Long-Acting MGF |
| Spend_MGF | VARCHAR(500) | Derived | PaidAmount when ActiveTreatment=1 and Short/Long-Acting MGF, else 0 |
| AlternativeCases_MGF | VARCHAR(500) | Derived | Always 0 |
| AlternativeSpend_MGF | VARCHAR(500) | Derived | PaidAmount when ActiveTreatment=1 and Short/Long-Acting MGF, else 0 |
| DenominatorCases_vbd | VARCHAR(500) | Derived | MemberID for VBD drugs with ActiveTreatment=1 and POS not 21/23 |
| DenominatorCases_MGF_SL | VARCHAR(500) | Derived | MemberID when Short/Long-Acting MGF |
| VBD_Group | VARCHAR(500) | Derived | 'VBD' when ServiceDetail in VBD drug list and POS not 21/23 |
| MGF-Short vs Long | VARCHAR(500) | Derived | 'MGF-Short vs Long' when Short/Long-Acting MGF and POS not 21/23 |
| MGF | VARCHAR(500) | Derived | 'MGF' when Short/Long-Acting MGF and ActiveTreatment=1 and POS not 21/23 |
| CPI | VARCHAR(500) | Derived | 'CPI' when Checkpoint Inhibitor and not YERVOY |

## AllPayers_OncoClaims_Final — Additional/Modified Columns

The final table is created via SELECT ... INTO with GROUP BY aggregation:

| Column | Difference from Staging | Notes |
|--------|------------------------|-------|
| HealthPlan Overall | New column | CASE: Molina variants→'Molina', CarePlus/Coventry/Simply→'Legacy', else keep name |
| AllowedUnits | SUM() | Aggregated |
| AllowedAmount | SUM() | Aggregated |
| PaidAmount | SUM() | Aggregated |
| MedicareAllowableIncurredYear | SUM() | Aggregated |
| ClaimCount | New column | COUNT(DISTINCT ClaimNumber) |
| DX1 | Modified | REPLACE(DX1,'.','') — dots stripped |
| DX2 | Modified | REPLACE(DX2,'.','') — dots stripped |
| CPT ServiceDetail Description | New column | CASE: uses ServiceDetail unless NULL or generic, then falls back to ProcedureCode-ServiceCodeDescription |
| MCA_MedicareAllow | SUM() | Aggregated |
| MCA_Paid | SUM() | Aggregated |
| totalpaidprocedure | SUM() | Aggregated |
| IsPreferred | Modified | For CPI: AdditionalCPI=0→'Yes', AdditionalCPI=1→'No'; else original IsPreferred |
| VBI Grouping | New column | Maps VBIGroup to categories: Biosimilars, Same Efficacy Substitutions, ESA, High Cost Anti Emetics, MGF, Pathway Conversions, Appropriate CPI Use |

**Columns EXCLUDED from Final** (present in staging but not in final): ClaimNumber, ClaimNumber_NoAdjRev, ClaimLine, AuthNumber, AdmitType_DERIVED, NoFFSPayment_Claim, NoFFSPayment_ClaimLine, Paid_Flag, all Denominator*/Cases*/Spend* VBI metric columns, BM_* benchmark columns.

## Analytical Usage Guide

### When to Use Which Table
| Scenario | Use This Table | Why |
|---|---|---|
| BI report metrics (PMPM, total cost, utilization) | `AllPayers_OncoClaims_Final` | Aggregated, filtered, has ClaimCount and VBI Grouping |
| VBI savings analysis (market share, DenominatorCases/Cases/Spend) | `AllPayers_OncoClaims` (staging) | VBI metric columns are excluded from Final |
| Individual claim investigation | `AllPayers_OncoClaims` (staging) | Has ClaimNumber, ClaimLine, AuthNumber |
| Membership/PMPM join | Either → join to `AllPayers_OncoMem` on `membershipkey` | Both tables have membershipkey |

### Key Analytical Columns — Usage Notes

**PaidAmount**
- Primary cost metric for all financial analysis
- Expected range: $0 - $50,000 per claim line (typical oncology infusion: $500-$15,000)
- $0 values may indicate: capitated claims, denied claims, or reversal lines
- Filter `WHERE PaidAmount > 0` for FFS cost analysis; or use NoFFSPayment flags
- In Final table: this is SUM(PaidAmount) per group — always use it directly, don't re-sum

**AllowedAmount**
- What the plan agreed to pay before member cost-sharing
- Always >= PaidAmount (the difference is member responsibility)
- Use for total cost of care analysis (plan + member perspective)
- Some clients don't populate this reliably — validate before using

**ActiveTreatment**
- 1 = patient is on active cancer-directed therapy; 0 = supportive care only or not flagged
- Critical for VBI analysis: many metrics (MGF, Pathway Conversions, Anti-BRAF) only count ActiveTreatment=1 patients
- Typical rate: 10-30% of oncology claims have ActiveTreatment=1
- If analyzing drug costs, segment by ActiveTreatment to separate treatment drugs from supportive care

**PlaceOfService_Derived**
- Key filter for VBI analysis: exclude '21' (Inpatient) and '23' (ER)
- '11' = Office, '22' = Outpatient Hospital — these are the primary oncology infusion settings
- Always use `COALESCE(PlaceOfService_Derived, '') NOT IN ('21','23')` to handle NULLs
- May be empty string for CountyCare records that weren't enriched

**ConditionCategory**
- The cancer type for the claim (Breast Cancer, Lung Cancer, etc.)
- NULL means the lookup against EDW.Dim.Unv_ConditionOnco failed — typically 5-15% of claims
- Multiple enrichment passes attempt to fill NULLs; CountyCare has additional passes
- Essential for condition-specific PMPM and VBI analysis (some VBI groups are condition-restricted)

**VBIGroup**
- NULL for ~85-95% of claims (only injectable oncology drugs in outpatient settings get classified)
- Non-NULL = this claim is relevant for VBI savings analysis
- Filtered after initial assignment (set to NULL if POS/condition criteria not met)
- Always pair with ConditionCategory for condition-restricted groups

**ServiceDetail**
- Drug brand name for oncology drugs (e.g., 'KEYTRUDA', 'AVASTIN', 'Neulasta')
- Generic catch-all values to watch for: 'Not Categorized', 'Cancer', 'Supportive', 'Standard', 'Infusion', 'Radiation', 'Optional', 'Hospital', 'Growth', 'Office', 'Surgery', 'Nursing Facility', 'Administration', 'Test', 'Other', 'ER', ''
- The Final table creates `CPT ServiceDetail Description` which falls back to ProcedureCode + ServiceCodeDescription when ServiceDetail is generic
- Use ServiceDetail for drug-level analysis; use ServiceCategory for broader service type analysis

**IsPreferred**
- 'Yes' = preferred/lower-cost option (biosimilar, generic, pathway-aligned)
- 'No' = non-preferred/higher-cost option (originator, brand, off-pathway)
- NULL = not applicable (claim doesn't have a VBI group or VBI group was filtered out)
- In Final table: overridden for CPI (AdditionalCPI=0 → 'Yes', AdditionalCPI=1 → 'No')
- Key metric: COUNT(DISTINCT MemberID WHERE IsPreferred='No') / COUNT(DISTINCT MemberID) = non-preferred rate

**membershipkey**
- Composite key linking claims to membership table
- Join pattern: `claims.membershipkey = membership.membershipkey`
- Critical for PMPM calculation — without this join you can't normalize cost by membership
- CarePlus/Coventry had a fix applied: 'MedicareNAALL' replaced with 'MedicareALL'

**MonthOfService vs MonthOfPayment**
- MonthOfService (YYYYMM): when the service occurred — use for incurred cost analysis
- MonthOfPayment (YYYYMM): when the claim was paid — use for cash flow analysis
- Payment typically lags service by 1-3 months
- Recent MonthOfService periods are affected by IBNR (incurred but not reported) — claims still being processed
- Final table filters both: MonthOfService >= 202301 AND MonthOfPayment <= current month - 1

**ClaimCount** (Final table only)
- COUNT(DISTINCT ClaimNumber) per aggregation group
- Use for utilization analysis (claims per member, claims per 1000)
- Not the same as row count — one row in Final may represent many claim lines

### Expected Value Ranges
| Column | Typical Range | Red Flag |
|---|---|---|
| PaidAmount (per line) | $0 - $50,000 | > $100K per line (verify if legitimate high-cost drug) |
| AllowedUnits | 1 - 100 | > 1000 (possible data error or unit mismatch) |
| MemberAge | 0 - 105 | Negative or > 120 |
| ClaimCount (Final, per group) | 1 - 50 | > 100 per member/month (possible aggregation issue) |
| MonthOfService | 202301+ | < 202301 (should be filtered out in Final) |

### Common Filter Patterns
```sql
-- FFS claims only (exclude capitated/denied)
WHERE PaidAmount > 0

-- Outpatient oncology (VBI-eligible settings)
WHERE COALESCE(PlaceOfService_Derived, '') NOT IN ('21','23')

-- Active treatment patients only
WHERE ActiveTreatment = 1

-- VBI-relevant claims only
WHERE VBIGroup IS NOT NULL

-- Specific VBI category
WHERE [VBI Grouping] = 'Biosimilars'

-- Exclude incomplete data
WHERE MonthOfService <= FORMAT(DATEADD(MONTH, -3, GETDATE()), 'yyyyMM')  -- exclude IBNR months

-- Non-generic ServiceDetail only
WHERE ServiceDetail NOT IN ('Not Categorized','Cancer','Supportive','Standard','Infusion',
    'Radiation','Optional','Hospital','Growth','Office','Surgery','Nursing Facility',
    'Administration','Test','Bone Marrow Biopsy','Diagnostic Testing Other','Other','ER','')
    AND ServiceDetail IS NOT NULL
```

**Final table WHERE filters:**
- `MonthofPayment <= FORMAT(DATEADD(MONTH,-1,GETDATE()),'yyyyMM')` — excludes current month
- `healthplan != 'SIMPLY'`
- `monthofservice >= 202301`
