# Source Tables and UDFs — Cost and Use Oncology Pipeline

## Overview
The Cost and Use pipeline references tables across multiple databases: Analytics, EDW, Contract, CostofCare, and StgDataLv2. This document catalogs each one.

---

## Analytics Database (pr-vm-andb-01)

### Analytics.dbo.ProspectClient_MedOnc_VBI_CPT
- **Purpose:** VBI group classification by CPT code
- **Key Columns:** CPTCode, VBIGroup, IsPreferred, ServiceDetail
- **Used In:** VBIGroup/IsPreferred/BudgetRollup assignment
- **Join:** `ProcedureCode_Derived = CPTCode WHERE VBIGroup IS NOT NULL`

### Analytics.dbo.ProspectClient_MedOnc_VBI_NDC
- **Purpose:** VBI group classification by NDC code (fallback when CPT doesn't match)
- **Key Columns:** NDC, VBIGroup, IsPreferred, ServiceDetail
- **Used In:** VBIGroup/IsPreferred/BudgetRollup assignment
- **Join:** `ProcedureCode_Derived = NDC WHERE VBIGroup IS NOT NULL`

### Analytics.dbo.ProspectClient_MedOnc_Benchmark_V13e
- **Purpose:** Industry benchmark data for VBI market share calculations
- **Key Columns:** Metric (=VBIGroup), CancerGroup (=ConditionCategory), LineOfBusiness, Denominator_Cases, Cases
- **Used In:** BM_DenominatorCases, BM_Cases, BM_MarketShare
- **Join:** `VBIGroup = Metric AND ConditionCategory = CancerGroup AND mapped_LOB = LineOfBusiness`
- **LOB Mapping:** INDIVIDUAL/COMMERCIAL → 'Marketplace'; Medicare Advantage → 'Medicare'; others direct

---

## EDW Database

### EDW.Fact.Unv_ClaimLine
- **Purpose:** Universal claim line fact table — links claims to dimension tables
- **Key Columns:** Rowid, ClaimNumber, ClaimLine, UnvConditionCategoryOncoSK, Unv_ClaimLineSK
- **Used In:** ConditionCategory lookup, FLBlue TIN enrichment
- **Join Patterns:**
  - ConditionCategory: `A.Rowid = B.Rowid AND A.ClaimNumber = B.ClaimNumber AND A.ClaimLine = B.ClaimLine` (multiple fallback passes)
  - FLBlue TIN: `A.Rowid = B.Rowid AND A.ClaimNumber = B.ClaimNumber AND A.ClaimLine = B.ClaimLine`

### EDW.Dim.Unv_ConditionOnco
- **Purpose:** Oncology condition category dimension
- **Key Columns:** UnvConditionOncoSK, ConditionCategory
- **Used In:** ConditionCategory assignment
- **Join:** `Unv_ClaimLine.UnvConditionCategoryOncoSK = Unv_ConditionOnco.UnvConditionOncoSK`
- **Filter:** `UnvConditionCategoryOncoSK != -1` (exclude unknown)

### EDW.Analytics.VwMasterUnvClaimLine
- **Purpose:** Master universal claim line view — denormalized claim detail
- **Key Columns:** ClaimNumber, ClaimLine, HealthPlan, Unv_ClaimLineSK, ServicingProviderGroupTIN, ServiceLine, ServiceClass, ServiceCategory, ServiceDetail, ServiceType, ServiceSubCategory, ProcedureCodeDerived
- **Used In:**
  - FLBlue TIN enrichment (via Unv_ClaimLineSK, WHERE ServicingProviderGroupTIN != 'NA')
  - CountyCare service hierarchy enrichment (WHERE HealthPlan = 'countycare')
- **Join Patterns:**
  - FLBlue: `Unv_ClaimLineSK` from Fact.Unv_ClaimLine
  - CountyCare: `ClaimNumber + ClaimLine + HealthPlan = 'countycare'`

### EDW.Analytics.Master_NDC_ClaimLine_PostPay
- **Purpose:** NDC claim line post-payment data including remark codes and auth outcomes
- **Key Columns:** ClaimNumber, ClaimLine, RemarkCode1, RemarkCode2, RemarkCode3, GHIS_OrgClmRemarkCodes_Line, AuthOutcome
- **Used In:** Remark Code Line and Auth Outcome assignment
- **Join:** `ClaimNumber + ClaimLine`
- **Remark Code Logic:**
  - S109: Extract first code before comma from GHIS_OrgClmRemarkCodes_Line
  - S114: Hardcode 'S114'
  - Default: RemarkCode1

### EDW.MSTR.OrganizationMaster_Curr
- **Purpose:** Organization/provider master dimension
- **Key Columns:** NPI, OrganizationName, OrganizationOtherName
- **Used In:** FLBlue ServicingGroupName enrichment
- **Join:** `CAST(ServicingProviderNPI AS VARCHAR) = CAST(NPI AS VARCHAR)`
- **Value:** `ISNULL(OrganizationName, OrganizationOtherName)`

---

## Contract Database

### Contract.MSTR.CPT_Curr
- **Purpose:** CPT code master with service hierarchy
- **Key Columns:** ServiceCode, ServiceCodeRank, ServiceCodeDescription, ServiceLine, ServiceClass, ServiceCategory, ServiceType, ServiceDetail, ServiceSubCategory
- **Used In:** ServiceCodeDescription, ServiceSubCategory, and CountyCare service hierarchy enrichment
- **Join:** `ProcedureCode_Derived = ServiceCode WHERE ServiceCodeRank = 1`

### CONTRACT.MSTR.NDC
- **Purpose:** NDC (National Drug Code) master
- **Key Columns:** NDC, DrugName, ServiceSubCategory
- **Used In:** ServiceCodeDescription fallback (when CPT lookup fails), ServiceSubCategory fallback
- **Join:** `ProcedureCode_Derived = NDC`

---

## CostofCare Database

### CostofCare.dbo.CountyCare_ABNPClaims_Processed
- **Purpose:** CountyCare ABNP (All But Not Paid) claims with DRG data
- **Key Columns:** ClaimNumber, ClaimLine, DOSFrom, APR_DRG_Derived
- **Used In:** DRG assignment for CountyCare claims
- **Join:** `ClaimNumber + ClaimLine + DateOfService = DOSFrom`

---

## StgDataLv2 Database

### StgDataLv2.ProspectClient.REF.APR_DRG
- **Purpose:** APR-DRG reference table
- **Key Columns:** APR_DRG
- **Used In:** DRG lookup for CountyCare claims
- **Join:** `APR_DRG = APR_DRG_Derived`

---

## User-Defined Functions

### dbo.UpperCaseWords()
- **Purpose:** Title-cases a string (capitalizes first letter of each word)
- **Used On:** ServiceClass, ServiceLine, ServiceDetail, ServiceCategory, ServicingProviderName, ServicingGroupName, ServiceCodeDescription, HealthPlan, LineOfBusiness, SubLineOfBusiness, ServiceSubCategory
- **Applied To:** Both AllPayers_OncoClaims and AllPayers_OncoMem
- **Note:** HealthPlan title-casing only for CAREPLUS, COUNTYCARE, SIMPLY, COVENTRY in membership table

---

## Stored Procedures (Client-Specific)

| Procedure | Purpose |
|-----------|---------|
| dbo.MolinaOnco_Proc | Generates Molina claims (##FinalPull_Molina) and membership (##MembershipMolina) |
| dbo.LegacyOnco_Proc | Generates Legacy claims (##FinalPull_Legacy_Onc) and membership (##MembershipLegacy_Onc) |
| dbo.LegacyOnco_Proc_Union | Additional Legacy processing |
| dbo.FLBlueOnco_Proc | Generates FLBlue claims (##FinalPull_FLBOnco) and membership (##FLBOncoMembership) |
| dbo.CountyCareOnco_Proc | Generates CountyCare claims (##FinalPull_CC_Oncology) and membership (##CareplusMembership_Onc) |
| dbo.CountyCare_Tin | Additional CountyCare TIN processing |

---

## Cross-Reference: Which Tables Are Used Where

| Source Table | VBI | ConditionCategory | Service Hierarchy | Remark/Auth | Provider | DRG |
|-------------|-----|-------------------|-------------------|-------------|----------|-----|
| ProspectClient_MedOnc_VBI_CPT | ✅ | | | | | |
| ProspectClient_MedOnc_VBI_NDC | ✅ | | | | | |
| ProspectClient_MedOnc_Benchmark_V13e | ✅ | | | | | |
| EDW.Fact.Unv_ClaimLine | | ✅ | | | ✅ (FLB) | |
| EDW.Dim.Unv_ConditionOnco | | ✅ | | | | |
| EDW.Analytics.VwMasterUnvClaimLine | | | ✅ (CC) | | ✅ (FLB) | |
| EDW.Analytics.Master_NDC_ClaimLine_PostPay | | | | ✅ | | |
| EDW.MSTR.OrganizationMaster_Curr | | | | | ✅ (FLB) | |
| Contract.MSTR.CPT_Curr | | | ✅ | | | |
| CONTRACT.MSTR.NDC | | | ✅ | | | |
| CostofCare.dbo.CountyCare_ABNPClaims_Processed | | | | | | ✅ (CC) |
| StgDataLv2.ProspectClient.REF.APR_DRG | | | | | | ✅ (CC) |
