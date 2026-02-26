---
name: costanduse-insights
description: "Expert guidance for analyzing Evolent PSA Cost & Use data and generating actionable insights. Covers the diagnostic framework, variance decomposition, driver classification, opportunity identification, and monthly narrative writing for both Cardiology and Oncology."
---

<!-- Trigger keywords: insights, analysis, trend, variance, drivers, opportunities, site of care, provider concentration, narrative, waterfall, decomposition, unfavorable, favorable -->

# Cost & Use Insights Skill

## Diagnostic Framework (5 Steps)

1. **Identify Variance** — Metrics with >±5% change warrant investigation
2. **Decompose Drivers** — Separate external (prevalence, mix, unit cost) from performance (utilization) factors
3. **Drill Down** — Service hierarchy → Provider → CPT → Site of Care
4. **Quantify Impact** — Convert percentages to dollar impacts
5. **Identify Opportunities** — Site-of-care shifts, pathway adherence, utilization outliers

---

## Standard Insight Structure

```
[Metric] increased/decreased by [%] ([$ impact])
├── Driven by [primary driver] (+/- $X)
│   └── [Sub-driver detail]
├── Offset by [secondary factor] (+/- $X)
└── Opportunity: [Actionable recommendation]
```

---

## Variance Decomposition Methodology

### Formulas

- **Prevalence Impact** = `(Prevalence CY - Prevalence PY) × PPPM PY`
- **Utilization Impact** = `(Util/K CY - Util/K PY) × Unit Cost PY / 1000`
- **Unit Cost Impact** = `(Unit Cost CY - Unit Cost PY) × Util/K CY / 1000`
- **Residual** = `Total PMPM Variance - Prevalence Impact - Utilization Impact - Unit Cost Impact`

### Python Implementation

```python
def decompose_pmpm_variance(comparison_df):
    prevalence_impact = (prevalence_cy - prevalence_py) * pppm_py
    util_impact = (util_cy - util_py) * unit_cost_py / 1000
    unit_cost_impact = (unit_cost_cy - unit_cost_py) * util_cy / 1000
    residual = pmpm_var - prevalence_impact - util_impact - unit_cost_impact
    
    return {
        'PMPM_PY': pmpm_py,
        'PMPM_CY': pmpm_cy,
        'PMPM_Var': pmpm_var,
        'PMPM_Pct': (pmpm_cy - pmpm_py) / pmpm_py,
        'Prevalence_Impact': prevalence_impact,
        'Utilization_Impact': util_impact,
        'UnitCost_Impact': unit_cost_impact,
        'Residual': residual,
        'Total_Dollar_Impact': pmpm_var * membership_cy,
    }
```

### Service-Level Decomposition

For each service in the hierarchy:
- **Util_Impact** = `UtilPerK_Var × UnitCost_PY / 1000 × Membership_CY`
- **UnitCost_Impact** = `UnitCost_Var × UtilPerK_CY / 1000 × Membership_CY`

---

## Driver Classification

### External (Unmanaged) Drivers

These are outside Evolent's control and trigger contractual **change events**:
- **Prevalence**: Changes in actively treated patient population
- **Condition/Cancer Mix**: Shift in patient condition distribution (e.g., more lung cancer vs breast cancer)
- **Unit Cost Changes**: Rate increases from providers or drug manufacturers
- **Actuarial Value (AV) / Benefit Richness**: Changes in plan benefit design

### Performance (Managed) Drivers

These are within Evolent's influence:
- **Utilization Trends**: Changes in service volume per 1,000 members
- **Site-of-Care Shifts**: Migration between office, hospital outpatient, ASC, inpatient
- **Pathway Adherence**: Compliance with recommended treatment protocols

### Classification Examples

| Scenario | Classification | Why |
|----------|---------------|-----|
| PMPM increase from new FDA indication expanding drug eligibility | External (Prevalence + ND&I) | Evolent cannot control FDA approvals |
| PMPM increase from more patients receiving drug at hospital OP vs office | Performance (Site-of-Care) | Evolent can influence site routing |
| Unit cost increase from WAC price increase on Keytruda | External (Unit Cost) | Evolent cannot control drug pricing |
| Utilization increase in imaging beyond clinical guidelines | Performance (Utilization) | Evolent can reinforce pathway adherence |
| Population shift from TANF to ABD (higher acuity) | External (Category of Aid Mix) | Population mix is external |

---

## Threshold Triggers

| Threshold | Action |
|-----------|--------|
| Variance > ±5% | Flag for investigation |
| $ Impact > $500K | Include in top drivers narrative |
| Provider concentration > 50% | Note site-specific opportunity |
| Hospital OP > 60% with ASC < 20% | Site-of-care shift opportunity |
| Single provider > 30% of service spend | Isolate for review |
| Unit cost increase > 10% | Investigate rate increases or mix shifts |
| Drug utilization spike | Monitor emerging indication expansion |

---

## Opportunity Templates

| Pattern | Opportunity Text |
|---------|------------------|
| High Hospital OP, low ASC | "Shifting appropriate cases from hospital outpatient to ASC could reduce trend" |
| Single provider dominance | "Isolate provider {name} with utilization significantly above average" |
| Unit cost spike | "Investigate rate increases or site-of-care mix shifts driving unit cost trend" |
| Drug utilization surge | "Monitor emerging indication expansion for {drug}" |
| Regimen variability | "Reinforce clinical pathways to reduce regimen variability" |
| Imaging intensity | "Review imaging utilization against clinical guidelines for potential reduction" |
| Device standardization | "Evaluate device selection patterns for standardization opportunities" |

---

## Site-of-Care Analysis

### Place of Service Codes

| POS Code | Name | Cost Factor | Description |
|----------|------|-------------|-------------|
| 11 | Office | 0.85x | Physician office — lowest cost |
| 22 | Hospital Outpatient | 1.15x | Hospital OP department — facility fees add cost |
| 24 | ASC | 0.90x | Ambulatory Surgical Center — mid-cost |
| 21 | Inpatient Hospital | 1.40x | Inpatient stay — highest cost |

### Analysis Approach

1. Calculate spend distribution across POS for each service
2. Flag services where Hospital OP > 60% and ASC < 20%
3. Estimate savings from shifting appropriate volume to lower-cost sites
4. Note: not all services are ASC-eligible (e.g., complex radiation, inpatient chemo)

### Python Implementation

```python
def generate_site_of_care_insights(claims_df, cy_periods, py_periods, service_filter=None):
    cy_claims = df[df['MonthOfService'].isin(cy_periods)]
    site_dist = cy_claims.groupby('PlaceOfServiceName')['PaidAmount'].sum()
    total = site_dist.sum()
    site_pct = (site_dist / total * 100).sort_values(ascending=False)
    
    top_site = site_pct.index[0]
    top_pct = site_pct.iloc[0]
    
    if top_pct > 50:
        insight = f"{top_pct:.0f}% of spend concentrated in {top_site} settings."
```

---

## Provider Concentration Analysis

### Approach

1. Rank providers by total PaidAmount within each service
2. Calculate cumulative % of total spend
3. Flag when top 3 providers account for > 40% of spend
4. Flag when single provider > 30% of service spend

### Python Implementation

```python
def generate_provider_concentration_insights(claims_df, cy_periods, service_filter=None, top_n=3):
    provider_spend = df.groupby('ServicingProvider')['PaidAmount'].sum().sort_values(ascending=False)
    total = provider_spend.sum()
    top_providers = provider_spend.head(top_n)
    top_pct = (top_providers.sum() / total) * 100
    
    if top_pct > 40:
        insight = f"Top {top_n} providers account for {top_pct:.0f}% of spend: {providers_str}"
```

---

## Service Driver Analysis

### Approach

1. Calculate PMPM_Impact for each service at the ServiceSubCategory level
2. Separate into **unfavorable** (positive PMPM_Impact = cost increase) and **favorable** (negative = cost decrease)
3. For each service, attribute PMPM impact to utilization vs unit cost components
4. Rank top 5 unfavorable and top 5 favorable by absolute PMPM_Impact

### Output Format

```
**{ServiceSubCategory}**: {$Impact} unfavorable, {driver type} ({$driver_impact})
```

Where driver type is either "utilization increase" or "unit cost increase" based on which component has greater absolute impact.

### Python Implementation

```python
def generate_service_driver_insights(service_df, top_n=5):
    unfavorable = service_df[service_df['PMPM_Impact'] > 0].nlargest(top_n, 'PMPM_Impact')
    favorable = service_df[service_df['PMPM_Impact'] < 0].nsmallest(top_n, 'PMPM_Impact')
    
    for _, row in unfavorable.iterrows():
        if abs(util_impact) > abs(uc_impact):
            driver = f"utilization increase ({format_currency(util_impact)})"
        else:
            driver = f"unit cost increase ({format_currency(uc_impact)})"
```

---

## Monthly Email Narrative Format

### Structure

```markdown
## Oncology Cost & Use Insights

### Oncology Trends
- Overall PMPM [increased/decreased] by [+X.X%] ([$X.XM] total impact).
- Primary driver: [Utilization/Unit Cost/Prevalence] ([$X.XM] impact).

### Performance Drivers by Impact

**Top Unfavorable:**
- **[Service]**: [$X.XM] unfavorable, [utilization/unit cost] increase ([$X.XK])
- **[Service]**: [$X.XK] unfavorable, [utilization/unit cost] increase ([$X.XK])

**Top Favorable:**
- **[Service]**: [$X.XK] favorable, [utilization/unit cost] decrease ([$X.XK])

### Opportunities
- **Site-of-Care Shift**: [Service] shows [X]% in hospital outpatient settings. Consider shifting appropriate cases to lower-cost ASC settings.
- **Utilization Management**: [Service] shows significant utilization increase ([$X.XM]). Review pathway adherence and emerging indications.
```

---

## Narrative Generation Functions (from insights.py)

| Function | Purpose | Key Output |
|----------|---------|------------|
| `generate_overview_insights(comparison_data)` | High-level PMPM trend + primary driver identification | List of insight strings |
| `generate_service_driver_insights(service_df, top_n)` | Top N unfavorable/favorable services with util vs UC attribution | Dict with 'unfavorable', 'favorable', 'opportunities' lists |
| `generate_site_of_care_insights(claims_df, cy_periods, py_periods)` | POS concentration analysis | List of insight strings |
| `generate_provider_concentration_insights(claims_df, cy_periods)` | Top provider spend % analysis | List of insight strings |
| `generate_opportunity_recommendations(service_df, claims_df, cy_periods)` | Site-of-care shift + utilization management recs | List of opportunity strings |
| `generate_full_narrative(comparison_data, service_df, claims_df, cy_periods, py_periods)` | Complete markdown narrative combining all above | Formatted markdown string |

### Full Narrative Assembly

```python
def generate_full_narrative(comparison_data, service_df, claims_df, cy_periods, py_periods):
    lines = []
    lines.append("## Oncology Cost & Use Insights\n")
    
    # 1. Overview section
    overview_insights = generate_overview_insights(comparison_data)
    
    # 2. Performance Drivers section  
    driver_insights = generate_service_driver_insights(service_df)
    
    # 3. Opportunities section
    opportunities = generate_opportunity_recommendations(service_df, claims_df, cy_periods)
    
    return '\n'.join(lines)
```

---

## Formatting Conventions

| Type | Format | Examples |
|------|--------|---------|
| Currency ≥ $1M | `$X.XM` | $3.3M, $1.5M |
| Currency ≥ $1K | `$X.XK` | $500.0K, $23.4K |
| Currency < $1K | `$X.XX` | $45.67, $8.50 |
| Percentage (positive) | `+X.X%` | +12.3%, +2.1% |
| Percentage (negative) | `-X.X%` or `X.X%` | -5.2% |
| Direction (cost increase) | "increased" | "PMPM increased by..." |
| Direction (cost decrease) | "decreased" | "Unit cost decreased by..." |

### Python Formatting Functions

```python
def format_currency(value):
    if abs(value) >= 1_000_000:
        return f"${value/1_000_000:.1f}M"
    elif abs(value) >= 1_000:
        return f"${value/1_000:.1f}K"
    else:
        return f"${value:.2f}"

def format_percent(value):
    return f"{value*100:+.1f}%"
```

---

## Cardiology-Specific Analysis

- **Active Patient Window**: 6 months (broader window due to chronic management)
- **Key Analysis Areas**:
  - **Site-of-care routing**: Hospital OP vs ASC for arrhythmia ablation procedures (PVI, SVT) — major opportunity
  - **Device standardization**: Evaluate device selection patterns (pacemakers, defibrillators, leads) for standardization savings
  - **Imaging intensity**: Review cardiac imaging utilization (echo, nuclear, CT, MRI) against clinical guidelines
  - **Key Service Lines**: Arrhythmia (ablation procedures — PVI, SVT), Heart Failure/Cardiomyopathy (device implants, imaging)
- **Typical Drivers**: Large unfavorable drivers often from ablation utilization increases at specific providers; favorable offsets from reduced imaging or device standardization

---

## Oncology-Specific Analysis

- **Active Patient Window**: 1 month (more acute treatment cycles)
- **Key Analysis Areas**:
  - **Pathway adherence**: Compliance with recommended treatment regimens — reduce regimen variability
  - **ND&I monitoring**: Track New Drugs & Indications for 36 months post-FDA approval to identify utilization ramp
  - **Checkpoint inhibitor utilization trends**: Keytruda (+12% util trend), Opdivo (+8%), Imfinzi (+10%), Tecentriq (-6% favorable)
  - **Targeted therapy expansion**: Enhertu (+23% util — FDA indication expansion), Darzalex Faspro (+9%), Padcev (-8% favorable — declining)
  - **Drug class spend**: Monitor high-cost drug spend by ServiceSubCategory
  - **VBI group analysis**: Value-Based Insurance design impact on utilization patterns
  - **Emerging indication monitoring**: Watch for off-label or newly approved indication use driving utilization spikes
- **Condition Groups** (7): Breast Cancer, Lung Cancer, Multiple Myeloma, Colorectal Cancer, Lymphoma, Prostate Cancer, Other
- **Typical Drivers**: Drug utilization increases (especially checkpoint inhibitors and new targeted therapies); favorable offsets from declining legacy chemotherapy utilization

---

## Change Event Identification

Change events are contractual cap rate adjustments triggered when external factors exceed thresholds:

### Triggers for Change Events

1. **Prevalence increase** > defined threshold → population growth beyond expected
2. **Unit cost increase** > contracted rate escalator → drug price or provider rate increases
3. **New Drugs & Indications (ND&I)** → FDA-approved within 36 months, not in original rate setting
4. **Condition/cancer mix shift** → population acuity change beyond expected

### Analysis Approach

- Calculate each external factor's impact using variance decomposition
- Compare to contracted thresholds
- Document evidence for change event submission
- Quantify dollar impact to support rate adjustment request

---

## Managed vs Unmanaged Trend Classification Rules

### Decision Tree

```
Is the PMPM variance driven by...
├── Population size/composition change? → UNMANAGED (Prevalence/Mix)
├── Drug price increase (WAC/ASP)? → UNMANAGED (Unit Cost)
├── New FDA indication expanding eligibility? → UNMANAGED (ND&I)
├── Benefit design change by health plan? → UNMANAGED (AV)
├── More services per patient? → MANAGED (Utilization)
├── Shift to higher-cost site? → MANAGED (Site-of-Care)
├── Deviation from recommended pathway? → MANAGED (Pathway Adherence)
└── Provider-specific utilization outlier? → MANAGED (Provider Practice Pattern)
```

### Examples with Dollar Attribution

- "Keytruda utilization increased +12% (+$2.1M) driven by emerging lung cancer indications" → **External** (ND&I) for new indication volume, **Performance** for utilization beyond expected ramp
- "IMRT spend shifted from office to hospital OP, adding $800K in facility fees" → **Performance** (Site-of-Care)
- "ABD population grew 8%, adding $1.5M in prevalence-driven cost" → **External** (Prevalence/Category of Aid Mix)
