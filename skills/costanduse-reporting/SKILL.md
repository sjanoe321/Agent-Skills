---
name: costanduse-reporting
description: "Expert guidance for building and maintaining Evolent PSA Cost & Use performance dashboards (Power BI and Streamlit). Covers all metrics, DAX patterns, data model, report structure, and implementation patterns for both Cardiology and Oncology."
---

<!-- Trigger keywords: cost and use report, Power BI, DAX, PMPM, metrics, dashboard, service hierarchy, data model, membership table, claims table, report structure -->

# Cost & Use Reporting Skill

## Business Context

- **Medical Expense Ratio (MER)**: Primary financial KPI = Total Medical Cost / Revenue. Revenue = capitated rates from health plans.
- **Managed vs. Unmanaged Trends**:
  - **Unmanaged (External)**: Prevalence, Condition/Cancer Mix, Unit Cost changes, AV/Benefit Richness — adjusted through contractual change events
  - **Managed (Performance)**: Utilization trends, site-of-care shifts, pathway adherence — within Evolent's influence
- **Change Events**: Contractual cap rate adjustments triggered when external factors (prevalence, unit cost, new drugs/indications) exceed defined thresholds

---

## Complete Metrics Dictionary

### Foundational Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **PMPM** | `TotalPaid / Membership` | Per Member Per Month cost — primary capitated rate basis |
| **PPPM** | `TotalPaid / ActivePatients` | Per Patient Per Month — adjusts for disease prevalence |
| **Membership** | `SUM(MemberMonths)` | Monthly eligible member count by subline of business (ABD, TANF, etc.) |
| **Active Patients** | `DISTINCTCOUNT(MemberID)` | Cardiology: CV encounter in past 6 months; Oncology: past 1 month |
| **Prevalence** | `ActivePatients / Membership` | Rate of actively treated patients in population |

### Utilization Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Utilization** | `DISTINCTCOUNT(ClaimNumber + LineNumber + CPTCode)` | Unique service line interactions |
| **Encounter** | `DISTINCTCOUNT(MemberID + DateOfService)` | Unique patient-date interactions |
| **Util/K** | `(Utilization / Membership) × 1000` | Utilization rate per 1,000 members |
| **Enc/1K** | `(Encounters / Membership) × 1000` | Encounter rate per 1,000 members |

### Cost Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Unit Cost** | `TotalPaid / Utilization` | Average paid per service unit |
| **Cost/Encounter** | `TotalPaid / Encounters` | Average paid per encounter |
| **Cost/Case** | `TotalPaid / Cases` | Average paid per treatment case (non-E&M services) |

### Adjustment Indices

| Index | Purpose |
|-------|---------|
| **Condition Mix Index** | Adjusts for shift in patient condition distribution |
| **Unit Cost Index** | Isolates unit cost changes controlling for procedure mix |
| **AV Index** | Actuarial value (benefit richness) ratio |
| **Category of Aid Mix** | Adjusts for Medicaid subline (ABD/TANF) population shifts |

### Impact Measures

| Metric | Formula | Description |
|--------|---------|-------------|
| **$ PMPM Impact** | `PMPM Variance × Membership` | Total dollar impact of PMPM change |
| **$ Unit Cost Impact** | `Unit Cost Variance × CY Units` | Dollar impact attributable to unit cost changes |
| **$ Utilization Impact** | `(Util/K CY - Util/K PY) × Membership × Unit Cost PY / 1000` | Dollar impact from utilization changes |

---

## DAX Calculation Patterns

### Period Comparison Pattern

```dax
Metric CY = CALCULATE(
    [BaseMetric], 
    TREATAS(VALUES('MOS CY'[MonthOfService]), Membership[monthofservice])
)

Metric PY = CALCULATE(
    [BaseMetric], 
    TREATAS(VALUES('MOS PY'[MonthOfService]), Membership[monthofservice])
)

Metric % = IFERROR(([Metric CY] - [Metric PY]) / [Metric PY], "--")
```

### Variance Pattern

```dax
Metric Var = [Metric CY] - [Metric PY]
```

### Impact Pattern

```dax
$ Impact = [Metric Var] * [Volume Measure CY]
```

---

## Power BI Report Structure

### Standard Tabs

1. **Overview** — High-level PMPM, Membership, Prevalence trends (CY vs PY)
2. **Service Detail** — Breakdown by ServiceLine → ServiceClass → ServiceCategory → ServiceSubCategory
3. **Practice Detail** — Provider/TIN-level analysis
4. **CPT Detail** — Procedure code-level granularity
5. **Condition Group Detail** — Trends by diagnosis grouping
6. **Service Drivers** — Waterfall analysis of trend components
7. **Dynamic Selection/Build Tabs** — Interactive filtering and custom views
8. **JOC Trend Summary/Monthly** — Journey of Care tracking

### Oncology-Specific Tabs

- **Top Costly Drugs** — Drug-level spend analysis
- **VBI Group/VBD tabs** — Value-Based Insurance design views
- **Drug and ServiceSub Drivers**

---

## Data Model

### Service Hierarchy

```
ServiceLine → ServiceClass → ServiceCategory → ServiceSubCategory → CPT
```

### Key Dimensions

- `healthplan` / `HealthPlan Overall`
- `lineofbusiness` / `sublineofbusiness` (ABD, TANF, etc.)
- `monthofservice` / `yearofservice`
- `conditiongroup`
- `NetworkType`
- `PlaceOfService` (POS 11=Office, POS 22=Hospital Outpatient, POS 24=ASC, POS 21=Inpatient Hospital)
- `ClaimType` (Professional, OP Facility, etc.)

### Required Data Tables

**Claims Table** columns:
ClaimID, ClaimLineNumber, MemberID, DateOfService, MonthOfService, YearOfService, HealthPlan, LineOfBusiness, SubLineOfBusiness, ConditionGroup, ServiceLine, ServiceClass, ServiceCategory, ServiceSubCategory, CPT, PlaceOfService, PlaceOfServiceName, ServicingProvider, ServicingTIN, PaidAmount, Units, ClaimType

**Membership Table** columns:
MonthOfService, YearOfService, HealthPlan, LineOfBusiness, SubLineOfBusiness, ConditionGroup, Membership, ActivePatients, Prevalence

**Service Hierarchy Mapping** columns:
CPT, ServiceSubCategory, ServiceCategory, ServiceClass, ServiceLine, AvgUnitCost

**Period Tables**: MOS CY and MOS PY for rolling comparison periods

### Key Relationships

- Claims to Membership via MonthOfService and dimension filters
- TREATAS pattern for period-based filtering without direct relationships

### Custom Visual Dependencies

- **Zebra BI Tables** — for variance waterfall visualizations
- **SuperTables** — for enhanced tabular displays

---

## Streamlit Dashboard Architecture

```
PSA_Dashboard/
├── app.py                    # Main Streamlit application (948 lines, 4 tabs)
├── requirements.txt
├── generate_sample_data.py   # Sample data generator
├── data/
│   ├── sample_claims.csv     # Claims data
│   ├── sample_membership.csv # Membership data
│   └── service_hierarchy.csv # Service hierarchy lookup
├── modules/
│   ├── __init__.py
│   ├── metrics.py            # Core metric calculations
│   ├── insights.py           # Narrative insight generation
│   └── theme.py              # Evolent brand colors/CSS
└── pages/                    # Streamlit multi-page support
```

### Dashboard Tabs

1. **Overview** — KPI cards (PMPM CY/PY/% /$ Impact), monthly trend line, breakdown by HealthPlan/LOB
2. **Performance Drivers** — Service-level waterfall, top unfavorable/favorable tables, utilization vs unit cost attribution
3. **Drill-Down Explorer** — Interactive hierarchy navigation: ServiceLine → ServiceClass → ServiceCategory → ServiceSubCategory, provider analysis, site-of-care analysis
4. **Insights Report** — Auto-generated narrative summary (markdown), exportable

---

## Python Calculation Engine

### `calculate_base_metrics(claims_df, membership_df, group_by)`

Aggregates claims and membership by `group_by` columns. Calculates: TotalPaid, Encounters, UniquePatients, TotalUnits, PMPM, PPPM, Prevalence, EncPerK, UtilPerK, CostPerEnc, UnitCost.

### `calculate_period_comparison(metrics_df, period_col, cy_periods, py_periods, group_by)`

Filters to CY/PY periods, aggregates, computes CY/PY metrics, variances (`_Var`), percent changes (`_Pct`), and dollar impacts (`PMPM_Impact`, `UnitCost_Impact`).

### `decompose_pmpm_variance(comparison_df)`

Decomposes PMPM variance into:
- **Prevalence_Impact** = (Prevalence CY - Prevalence PY) × PPPM PY
- **Utilization_Impact** = (Util/K CY - Util/K PY) × Unit Cost PY / 1000
- **UnitCost_Impact** = (Unit Cost CY - Unit Cost PY) × Util/K CY / 1000
- **Residual** = Total PMPM Var - Prevalence - Utilization - Unit Cost

### `calculate_service_level_metrics(claims_df, membership_df, cy_periods, py_periods, hierarchy_level)`

Aggregates to service level, calculates PMPM/UtilPerK/UnitCost by CY/PY, variances, and decomposes PMPM impact into Util_Impact and UnitCost_Impact per service.

---

## Evolent Brand Colors

| Token | Hex | Usage |
|-------|-----|-------|
| primary_dark | `#020623` | Main text |
| primary_purple | `#5D3791` | Primary brand, headers, chart accent |
| secondary_purple | `#4C51A6` | Secondary accent |
| blue | `#3475C1` | Links, secondary charts |
| light_blue | `#17A5E6` | Tertiary accent |
| teal | `#08DCE2` | **Favorable** indicators (cost decrease) |
| cyan | `#08F0D4` | Additional accent |
| magenta | `#7B1C92` | **Unfavorable** indicators (cost increase) |
| gray | `#9FA7AE` | Secondary text |
| light_gray | `#F5F5F7` | Light backgrounds |

**Font**: Segoe UI, Arial, sans-serif

---

## Cardiology-Specific Context

- **Active Patient Definition**: Member with cardiovascular encounter in past 6 months
- **Case Definition**: Patient receiving non-E&M cardiovascular service
- **Key Service Lines**: Arrhythmia (ablation procedures — PVI, SVT), Heart Failure/Cardiomyopathy (device implants, imaging)
- **Common Opportunities**: Site-of-care routing (Hospital OP vs ASC), device standardization, imaging intensity reduction

---

## Oncology-Specific Context

- **Active Patient Definition**: Member with oncology encounter in past 1 month (more acute care cycle)
- **Key Drug Classes**: Checkpoint inhibitors (Keytruda/J9271, Opdivo/J9299, Imfinzi/J9173, Tecentriq/J9022), targeted therapies (Enhertu/J9358, Darzalex Faspro/J9144, Padcev/J9177)
- **Service Hierarchy** (14 services): Immunotherapy (4), Targeted Therapy (3), Chemotherapy (2), Radiation Oncology (2), Supportive Care (2), E&M (1)
- **Condition Groups** (7): Breast Cancer, Lung Cancer, Multiple Myeloma, Colorectal Cancer, Lymphoma, Prostate Cancer, Other
- **New Drugs & Indications (ND&I)**: Tracked for 36 months post-FDA approval
- **Common Opportunities**: Site-of-care concentration, pathway adherence, emerging indication monitoring

---

## Building New Reports Checklist

1. Obtain Claims, Membership, and Service Hierarchy data tables with required columns
2. Define comparison periods (MOS CY / MOS PY — typically rolling 12 months)
3. Map CPT codes to service hierarchy (ServiceSubCategory → ServiceCategory → ServiceClass → ServiceLine)
4. Calculate base metrics using `calculate_base_metrics()` or equivalent DAX
5. Run period comparison via `calculate_period_comparison()` or TREATAS-based DAX
6. Decompose PMPM variance into prevalence, utilization, unit cost components
7. Calculate service-level metrics for driver analysis
8. Build visualizations: KPI cards, trend lines, waterfall charts, drill-down tables
9. Apply Evolent brand theme (colors, fonts, card styling)
10. Generate automated insights using insight generation module
