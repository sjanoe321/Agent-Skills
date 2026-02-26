# VBI Logic — Cost and Use Oncology Pipeline

## Overview
The VBI logic enriches claims with drug group classifications, preferred/non-preferred status, benchmark comparisons, and savings metrics. This is the most complex part of the pipeline and drives the core analytics in the Cost and Use BI report.

---

## Clinical & Economic Rationale

The VBI (Value-Based Insurance) framework exists to identify and quantify savings opportunities across five strategic categories of oncology drug spend:

### VBI Grouping Categories — Why They Matter

**Same Efficacy Substitutions** (Taxane, Anthracycline, Iron Product, LHRH, Bone Agents, Folic Acid Analog, Pemetrexed, Hypomethylating Agents, mTOR Inhibitor, Tyrosine Kinase Inhibitor, TPO Agonist, PARP Inhibitor, Lanreotide, Zepzelca)
- **Clinical rationale:** Multiple drugs in these classes have equivalent clinical efficacy, but significant cost differences exist (brand vs generic, older vs newer formulation)
- **Economic logic:** IsPreferred='Yes' = lower-cost equivalent available; IsPreferred='No' = patient on higher-cost option
- **Savings mechanism:** Switching from non-preferred to preferred saves the cost differential per administration
- **Typical savings:** 20-60% per administration depending on the drug class
- **How to interpret Cases/Spend:** Cases = member IDs of patients on non-preferred drugs; Spend = their total drug cost; AlternativeCases/AlternativeSpend = patients already on preferred (the good behavior to emulate)

**Biosimilars** (Bevacizumab, Rituximab, Trastuzumab)
- **Clinical rationale:** Biosimilars are FDA-approved as clinically equivalent to reference biologics. No meaningful efficacy or safety difference.
- **Economic logic:** Biosimilars cost 30-50% less than originator brands (Avastin, Rituxan, Herceptin)
- **Savings mechanism:** Converting patients from originator to biosimilar. IsPreferred='Yes' = biosimilar; IsPreferred='No' = originator brand.
- **Why this is the highest-impact opportunity:** Biologic drugs are among the most expensive in oncology ($5K-$15K per administration). A 40% savings on high-volume biologics = millions of dollars.
- **How to interpret:** Market share = % of patients still on originator. Industry trend is toward 50-70% biosimilar adoption.

**Pathway Conversions** (Adcetris, Cyramza, Perjeta, Provenge)
- **Clinical rationale:** These are high-cost drugs with narrow clinical pathway indications. Evidence-based guidelines recommend them only in specific clinical scenarios (specific disease stage, after prior therapy failure, etc.)
- **Economic logic:** ALL active-treatment patients using these drugs are counted as "Cases" because the drug itself is the cost driver — the question is whether the patient truly meets pathway criteria.
- **Savings mechanism:** Better clinical pathway adherence. The 10% AlternativeSpend assumption (PaidAmount × 0.10) estimates that with perfect pathway adherence, only 10% of current spend would remain (the truly indicated uses). In reality, achievable savings are typically 30-50%.
- **Why Provenge is special:** Provenge (sipuleucel-T) costs ~$93K for a treatment course. Very narrow indication (asymptomatic/minimally symptomatic metastatic castrate-resistant prostate cancer). Any use outside this indication is extremely high-cost waste.

**Appropriate CPI Use** (Checkpoint Inhibitor)
- **Clinical rationale:** Checkpoint inhibitors (CPIs) within a class (e.g., PD-1 inhibitors) have similar mechanisms. Switching from one CPI to another without disease progression is clinically questionable and wasteful. The exception is OPDIVO+YERVOY combination (PD-1 + CTLA-4 = different mechanisms, approved combination).
- **Economic logic:** CPI therapy costs $150K-$200K/year. Even a small overuse rate = significant dollars.
- **Savings mechanism:** Reducing unnecessary CPI switching. AdditionalCPI=1 flags potential overuse.
- **How DenominatorCases works for CPI:** Unlike other groups (which count MemberIDs), CPI uses CAST(PaidAmount AS VARCHAR) as DenominatorCases. This means the "denominator" is total CPI spend, and "Cases" is overuse spend. Market share = overuse spend / total CPI spend.
- **The YERVOY exception:** YERVOY (ipilimumab) is excluded from CPI tracking because it's a CTLA-4 inhibitor (different mechanism class) and is often used in approved combination with OPDIVO (nivolumab, a PD-1 inhibitor). The 6-month window for OPDIVO/YERVOY pairs prevents flagging approved combination therapy as overuse.

**MGF** (Short-Acting MGF, Long-Acting MGF)
- **Clinical rationale:** MGF (myeloid growth factors) prevent neutropenia during chemotherapy. Short-acting (filgrastim, daily injection) and long-acting (pegfilgrastim, one injection per cycle) are both effective.
- **Economic logic:** Long-acting costs ~3x per administration but is more convenient. Short-acting biosimilars are 50-70% cheaper than long-acting brands.
- **Why tracked separately as MGF-Short vs Long:** This is a utilization pattern analysis — what proportion of MGF use is long-acting (more expensive per cycle) vs short-acting?
- **Why ActiveTreatment matters for MGF:** MGF is only clinically indicated during active chemotherapy. MGF without active treatment suggests inappropriate use. The MGF flag = Short/Long-Acting MGF + ActiveTreatment=1 + POS not 21/23.

**ESA** (Erythropoiesis-Stimulating Agents)
- **Clinical rationale:** ESAs stimulate red blood cell production for chemotherapy-induced anemia. Guidelines restrict use to hemoglobin <10 g/dL. Overuse carries cardiovascular and tumor progression risks.
- **Economic logic:** Biosimilar available (Retacrit vs Epogen/Procrit/Aranesp). Substitution + appropriate use monitoring.

**High Cost Anti Emetics**
- **Clinical rationale:** Anti-nausea drugs for chemotherapy. Premium agents (e.g., Aloxi IV, Emend IV) are significantly more expensive than equally effective oral alternatives.
- **Economic logic:** All patients receiving these drugs are potential cases for intervention since cheaper alternatives exist for most scenarios.

---

## Step 1: VBIGroup and IsPreferred Assignment

**Source Tables:**
- `Analytics.dbo.ProspectClient_MedOnc_VBI_CPT` — joined on `ProcedureCode_Derived = CPTCode`
- `Analytics.dbo.ProspectClient_MedOnc_VBI_NDC` — joined on `ProcedureCode_Derived = NDC`

**Fields Set:**
```sql
UPDATE A
SET VBIGroup = COALESCE(b.VBIGroup, n.VBIGroup),
    IsPreferred = COALESCE(b.IsPreferred, n.IsPreferred),
    BudgetRollup = COALESCE(b.ServiceDetail, n.ServiceDetail)
FROM DBO.Allpayers_OncoClaims A
LEFT JOIN Analytics.dbo.ProspectClient_MedOnc_VBI_CPT b ON a.ProcedureCode_Derived = b.CPTCode AND b.VBIGroup IS NOT NULL
LEFT JOIN Analytics.dbo.ProspectClient_MedOnc_VBI_NDC n ON a.ProcedureCode_Derived = n.NDC AND n.VBIGroup IS NOT NULL
```

CPT lookup takes precedence over NDC (via COALESCE order).

---

## Step 2: VBIGroup Filtering by PlaceOfService and ConditionCategory

After initial assignment, VBIGroup is **filtered** (set to NULL if conditions aren't met). The core rule: **POS 21 (Inpatient Hospital) and 23 (ER) are excluded** for all VBI groups.

### Universal Groups (POS not 21/23 only)
These VBI groups are kept regardless of ConditionCategory:
- Adcetris, Cyramza, High-Cost Antiemetic, MGF, Perjeta, Provenge, Zepzelca
- Checkpoint Inhibitor, Iron Product, Bone Agents, Pemetrexed, TPO Agonist
- Bevacizumab, ESA, Lanreotide, Rituximab, Trastuzumab
- Short-Acting MGF, Long-Acting MGF

### Condition-Specific Groups (POS not 21/23 AND specific ConditionCategory)
| VBIGroup | Required ConditionCategory |
|----------|--------------------------|
| Taxane | NOT 'Pancreatic Cancer' |
| Anthracycline | Breast Cancer, Lymphoma |
| LHRH | Breast Cancer, Prostate Cancer |
| Folic Acid Analog | Small Intestine / Colorectal Cancer, Sarcoma |
| Hypomethylating Agents | MDS |
| mTOR Inhibitor | Sarcoma |
| Tyrosine Kinase Inhibitor | Gastro/Esophageal Cancer, Small Intestine / Colorectal Cancer, Acute Leukemia, Chronic Leukemia |
| Anti-BRAF Agent-BRAF Inhibitor | Malignant Melanoma |
| Anti-BRAF Agent-MEK Inhibitor | Malignant Melanoma |
| PARP Inhibitor | Breast Cancer |

### VBD Group (POS not 21/23 AND ServiceDetail in drug list)
VBIGroup='VBD' is kept when ServiceDetail is in the approved VBD drug list (see Drug Lists section below).

---

## Step 3: AdditionalCPI (CPI Overuse Detection)

Identifies patients receiving additional Checkpoint Inhibitor therapy beyond their first CPI claim:

1. **Build #iCPI temp table**: First CPI claim per member (ROW_NUMBER=1, ordered by DateOfService), excluding YERVOY
2. **Update AdditionalCPI**:
   - `1` if the claim's MonthOfService > first CPI month AND ServiceDetail differs from first CPI ServiceDetail
   - Exception: OPDIVO/YERVOY pairs within 6 months of each other are excluded (combination therapy)
   - `0` otherwise

---

## Step 4: Derived Flag Columns

| Flag Column | Logic |
|------------|-------|
| VBD_Group | 'VBD' when ServiceDetail in VBD drug list AND POS not 21/23 |
| MGF-Short vs Long | 'MGF-Short vs Long' when VBIGroup in (Short-Acting MGF, Long-Acting MGF) AND POS not 21/23 |
| MGF | 'MGF' when VBIGroup in (Short-Acting MGF, Long-Acting MGF) AND ActiveTreatment=1 AND POS not 21/23 |
| CPI | 'CPI' when VBIGroup='Checkpoint Inhibitor' AND ServiceDetail != 'YERVOY' |

---

## Step 5: DenominatorCases / Cases / Spend Calculations

These are the core VBI metrics. All stored as VARCHAR(500).

### How to Interpret These Metrics

**Important:** These columns are stored as VARCHAR(500), not numeric. Always CAST to FLOAT/DECIMAL before doing math.

**The Denominator/Cases/Spend framework works like this:**
- **DenominatorCases** = Who is eligible to be measured? (total population for this VBI group)
- **Cases** = Who is using the non-preferred/overuse option? (the "problem")
- **Spend** = How much are the "problem" cases costing?
- **AlternativeCases** = Who is already on the preferred option? (the "good behavior")
- **AlternativeSpend** = What would the spend look like if everyone used the preferred option?
- **Market Share** = Cases / DenominatorCases (what % is non-preferred)
- **Savings Opportunity** = Spend - AlternativeSpend (how much could be saved)

**Why MemberID is used as Cases (not a count):**
The actual MemberID value is stored in the Cases column (not a count). To get the count, you must use `COUNT(DISTINCT Cases)` in aggregation. This design allows both counting unique patients AND linking back to specific members.

### DenominatorCases
| VBIGroup Category | Value |
|------------------|-------|
| Substitution groups (Taxane, Anthracycline, Iron Product, LHRH, Bone Agents, Folic Acid Analog, Pemetrexed, Hypomethylating Agents, mTOR Inhibitor, Tyrosine Kinase Inhibitor, TPO Agonist, PARP Inhibitor, Bevacizumab, ESA, Lanreotide, Rituximab, Trastuzumab, Short-Acting MGF, Long-Acting MGF, MGF-Short vs Long) | MemberID |
| Anti-BRAF groups (BRAF Inhibitor, MEK Inhibitor) | MemberID when ActiveTreatment=1 |
| Checkpoint Inhibitor | CAST(PaidAmount AS VARCHAR) |

### Cases (Non-Preferred/Overuse)
| VBIGroup Category | Value |
|------------------|-------|
| Substitution groups | MemberID when IsPreferred='No' |
| Anti-BRAF groups | MemberID when ActiveTreatment=1 AND IsPreferred='No' |
| Pathway groups (Adcetris, Cyramza, MGF, Perjeta) | MemberID when ActiveTreatment=1 |
| Volume groups (High-Cost Antiemetic, Provenge, Zepzelca) | MemberID (unconditional) |
| Checkpoint Inhibitor | CAST(PaidAmount AS VARCHAR) |

### Spend
| VBIGroup Category | Value |
|------------------|-------|
| Substitution groups | PaidAmount when IsPreferred='No' |
| Anti-BRAF groups | PaidAmount when ActiveTreatment=1 AND IsPreferred='No' |
| Pathway groups (Adcetris, Cyramza, MGF, Perjeta, Provenge) | PaidAmount when ActiveTreatment=1 |
| Volume groups (High-Cost Antiemetic, Zepzelca) | PaidAmount (unconditional) |
| Checkpoint Inhibitor | PaidAmount |

### AlternativeCases
| VBIGroup Category | Value |
|------------------|-------|
| Substitution groups | MemberID when IsPreferred='Yes' |
| Anti-BRAF groups | MemberID when ActiveTreatment=1 AND IsPreferred='Yes' |
| All others (Adcetris, Cyramza, High-Cost Antiemetic, MGF, Perjeta, Provenge, Zepzelca, Checkpoint Inhibitor) | '0' |

### AlternativeSpend
| VBIGroup Category | Value |
|------------------|-------|
| Substitution groups | PaidAmount when IsPreferred='Yes' |
| Anti-BRAF groups | PaidAmount when ActiveTreatment=1 AND IsPreferred='Yes' |
| Pathway groups (Adcetris, Cyramza, MGF, Perjeta, Provenge) | PaidAmount * (1 - 0.90) = 10% of PaidAmount when ActiveTreatment=1 |
| Volume groups (High-Cost Antiemetic, Zepzelca) | PaidAmount * (1 - 0.90) = 10% |
| Checkpoint Inhibitor | 0 |

### MGF-Specific Metrics
| Column | Logic |
|--------|-------|
| Cases_MGF_SL | MemberID when VBIGroup='Long-Acting MGF' |
| Spend_MGF_SL | PaidAmount when Long-Acting MGF, else 0 |
| AlternativeCases_MGF_SL | MemberID when VBIGroup='Short-Acting MGF' |
| AlternativeSpend_MGF_SL | PaidAmount when Short-Acting MGF, else 0 |
| Cases_MGF | MemberID when ActiveTreatment=1 AND Short/Long-Acting MGF |
| Spend_MGF | PaidAmount when ActiveTreatment=1 AND Short/Long-Acting MGF, else 0 |
| AlternativeCases_MGF | Always 0 |
| AlternativeSpend_MGF | PaidAmount when ActiveTreatment=1 AND Short/Long-Acting MGF, else 0 |
| DenominatorCases_MGF_SL | MemberID when Short/Long-Acting MGF |

### CPI-Specific Metrics
| Column | Logic |
|--------|-------|
| DenominatorCases_CPI | MemberID when VBIGroup='Checkpoint Inhibitor' AND ServiceDetail != 'YERVOY' |
| Cases_CPI | MemberID when AdditionalCPI=1 AND VBIGroup='Checkpoint Inhibitor' AND not YERVOY |
| Spend_CPI | PaidAmount when AdditionalCPI=1 AND CPI AND not YERVOY, else 0 |
| AlternativeCases_CPI | Always 0 |
| AlternativeSpend_CPI | Always 0 |

### Other Denominator/Volume Metrics
| Column | Logic |
|--------|-------|
| DenominatorCases_agg | MemberID when ActiveTreatment=1 AND POS not 21/23 |
| DenominatorCases_vbd | MemberID for VBD drugs with ActiveTreatment=1 AND POS not 21/23 |
| Spend_vbd | PaidAmount for VBD drugs with ActiveTreatment=1 AND POS not 21/23 |
| Cases_vbd | PaidAmount for VBD drugs with JW modifier (Modifier1 or Modifier2 LIKE '%JW%') AND POS not 21/23 |

### JW Modifier — Drug Waste Tracking

The JW modifier on a medical claim indicates that the provider is reporting drug waste (unused portion of a single-use vial that was discarded). In VBD drug tracking:

- **Cases_vbd** specifically filters for claims with `Modifier1 LIKE '%JW%' OR Modifier2 LIKE '%JW%'`
- This identifies VBD drug claims where waste was reported
- **Why it matters economically:** Drug waste is a significant cost driver in oncology. Single-use vials often contain more drug than needed for a patient's weight-based dose. The waste is paid for but not used clinically.
- **Analytical use:** High JW rates on expensive VBD drugs suggest an opportunity for waste reduction through dose rounding, vial sharing (where allowed), or selecting vial sizes closer to typical doses.
- **Note:** Cases_vbd stores PaidAmount (not MemberID) when the JW modifier is present — this captures the dollar value of waste-associated claims.

---

## Step 6: Benchmark Data

**Source:** `Analytics.dbo.ProspectClient_MedOnc_Benchmark_V13e`

**Join:**
```sql
LEFT JOIN Analytics.dbo.ProspectClient_MedOnc_Benchmark_V13e b
    ON a.VBIGroup = b.Metric
    AND a.ConditionCategory = b.CancerGroup
    AND (CASE 
           WHEN a.LineOfBusiness IN ('INDIVIDUAL','COMMERCIAL') THEN 'Marketplace'
           WHEN a.LineOfBusiness = 'Medicare Advantage' THEN 'Medicare'
           ELSE a.LineOfBusiness 
         END) = b.LineOfBusiness
```

**LOB Mapping for Benchmarks:**
| Claims LOB | Benchmark LOB |
|-----------|--------------|
| INDIVIDUAL | Marketplace |
| COMMERCIAL | Marketplace |
| Medicare Advantage | Medicare |
| All others | Direct match |

**Fields Set:**
- `BM_DenominatorCases = COALESCE(b.Denominator_Cases, 0)`
- `BM_Cases = COALESCE(b.Cases, 0)`

### BM_MarketShare Calculation
- **Non-CPI**: `ROUND(COALESCE(BM_Cases / NULLIF(BM_DenominatorCases, 0), 0), 2)`
- **CPI**: Same formula but capped at 1.0 (if result > 1, set to 1)

### Interpreting Benchmark Comparisons

**Reading the results:**
- `Actual Market Share > BM_MarketShare` → Your plan has MORE non-preferred use than industry average → **Savings opportunity exists**
- `Actual Market Share < BM_MarketShare` → Your plan is performing BETTER than industry average → **Celebrate and maintain**  
- `Actual Market Share ≈ BM_MarketShare` → At industry average → Limited opportunity from this group alone

**Quantifying the opportunity:**
```sql
-- Simplified savings opportunity per VBI group
Savings = (Actual_MarketShare - BM_MarketShare) × Total_Spend_In_Category
```

**Caveats:**
- Benchmarks are from version V13e — verify the data vintage
- Small DenominatorCases (< 30 members) make market share unreliable — don't draw conclusions from small samples
- Some conditions have legitimately different utilization patterns (e.g., academic medical centers may use more originators for clinical trial alignment)

---

## Step 7: VBI Grouping (Final Table Only)

In AllPayers_OncoClaims_Final, VBIGroup is mapped to higher-level VBI Grouping categories:

| VBIGroup | VBI Grouping |
|----------|-------------|
| Checkpoint Inhibitor | Appropriate CPI Use |
| Bevacizumab | Biosimilars |
| Rituximab | Biosimilars |
| Trastuzumab | Biosimilars |
| ESA | ESA |
| High-Cost Antiemetic | High Cost Anti Emetics |
| Long-Acting MGF | MGF |
| Short-Acting MGF | MGF |
| Adcetris | Pathway Conversions |
| Cyramza | Pathway Conversions |
| Perjeta | Pathway Conversions |
| Provenge | Pathway Conversions |
| Anthracycline | Same Efficacy Substitutions |
| Bone Agents | Same Efficacy Substitutions |
| Folic Acid Analog | Same Efficacy Substitutions |
| Iron Product | Same Efficacy Substitutions |
| Lanreotide | Same Efficacy Substitutions |
| LHRH | Same Efficacy Substitutions |
| Pemetrexed | Same Efficacy Substitutions |
| Taxane | Same Efficacy Substitutions |
| Zepzelca | Same Efficacy Substitutions |

### IsPreferred Override for CPI (Final Table)
```sql
CASE 
  WHEN VBIGroup = 'Checkpoint Inhibitor' AND AdditionalCPI = 0 THEN 'Yes'  -- Appropriate use
  WHEN VBIGroup = 'Checkpoint Inhibitor' AND AdditionalCPI = 1 THEN 'No'   -- Overuse
  ELSE IsPreferred 
END AS IsPreferred
```

---

## Drug Lists

### VBD Drug List
Used for VBD_Group, DenominatorCases_vbd, Spend_vbd, Cases_vbd:

**Core drugs:**
ABRAXANE, ADCETRIS, ALIMTA, AVASTIN, BESPONSA, CYRAMZA, DARZALEX, EMPLICITI, ERBITUX, HERCEPTIN, KADCYLA, KANJINTI, KYPROLIS, MVASI, NPLATE, RITUXAN, VECTIBIX, YERVOY, Padcev, Enhertu, Reblozyl, Trodelvy, Oncaspar, Elahere, Polivy, Ruxience, Zirabev, Poteligeo, Tecvayli, Onivyde, Riabni, Sarclisa, Zepzelca, Tivdak, Truxima, Halaven, Folotyn, Monjuvi

**Additional (not in original PDF):**
Paclitaxel

**Additional from ClinOps PDF:**
Adynma, Adakveo, Alymsys, Arranon, Asparlas, Avzivi, Beleodaq, Clolar, Cosela, Danyelza, Docivyx, Doxil, Elzonris, Gamifant, Hepzato, Hercessi, Istodax, Ixempra, Lartruvo, Loqtorzi, Lymphir, Margenza, Nplate, Pemrydi, Rylaze, Rytelo, Synribo, Talvey, Treanda, Trisenox, Unituxin, Vegzelma, Vyloy, VyxEOS, Yondelis, Zynlonta

**Removed in Jira ticket but found in PDF:**
Jevtana

**Note:** The VBD drug list appears in multiple UPDATE statements and must be kept in sync across: VBIGroup='VBD' filtering, VBD_Group assignment, DenominatorCases_vbd, Spend_vbd, and Cases_vbd.
