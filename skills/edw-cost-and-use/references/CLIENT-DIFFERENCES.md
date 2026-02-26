# Client Differences — Cost & Use Oncology Pipeline

## Overview
The AllPayers_OncoClaims table is built by UNION ALL of 5 client-specific claims tables. Each client has different data availability, column mappings, and enrichment requirements. This document details every difference.

---

## Molina
**Stored Procedure:** `dbo.MolinaOnco_Proc`  
**Claims Table:** `DBO.MolinaOncoClaims` (from `##FinalPull_Molina`)  
**Membership Table:** `DBO.MolinaOncoMembership` (from `##MembershipMolina`)  
**Health Plans:** MOLINA, MOLINA-IL, MOLINA-MI, and other variants

### Column Mapping
- **Full fidelity** — all standard columns are populated directly from the stored procedure
- All fields map 1:1 to the union schema
- No empty-string placeholders needed

### Special Processing
- **MMP duplicate handling**: For SubLineOfBusiness='MMP' and HEALTHPLAN IN ('MOLINA-IL','MOLINA-MI'), claims ending in 'M' have AllowedUnits zeroed out if a matching non-M claim exists (prevents double-counting Medicare crossover claims)

---

## Legacy (CarePlus, Coventry)
**Stored Procedure:** `dbo.LegacyOnco_Proc` + `dbo.LegacyOnco_Proc_Union`  
**Claims Table:** `DBO.LegacyOncoClaims` (from `##FinalPull_Legacy_Onc`)  
**Membership Table:** `DBO.LegacyOncoMembership` (from `##MembershipLegacy_Onc`)  
**Health Plans:** CAREPLUS, COVENTRY (SIMPLY excluded)

### Column Mapping Differences
| Union Column | Legacy Source | Notes |
|-------------|-------------|-------|
| ServicingProviderName | ServicingGroupName | Group name used as provider name |

All other columns map 1:1.

### Special Filters
- **Membership**: `WHERE HEALTHPLAN != 'SIMPLY'` — SIMPLY is excluded from the membership union
- **Claims**: No SIMPLY exclusion in claims union (handled in final table filter)

### Special Processing
- **membershipkey fix**: `REPLACE(membershipkey,'MedicareNAALL','MedicareALL')` for CAREPLUS and COVENTRY in AllPayers_OncoMem

---

## CountyCare
**Stored Procedures:** `dbo.CountyCareOnco_Proc` + `dbo.CountyCare_Tin`  
**Claims Table:** `DBO.CCOncoClaims` (from `##FinalPull_CC_Oncology`)  
**Membership Table:** `DBO.CCOncoMembership` (from `##CareplusMembership_Onc`)  
**Health Plans:** COUNTYCARE

### Column Mapping Differences
| Union Column | CC Source | Notes |
|-------------|----------|-------|
| ServicingGroupTIN | '' (empty string) | Not available in source |
| ServicingProviderName | `CASE WHEN ServicingGroupName IS NULL THEN ProviderName ELSE ServicingGroupName END` | Fallback to ProviderName |
| ServicingProviderNPI | '' (empty string) | Not available |
| AccountType | '' (empty string) | Not available |
| ProcedureCode_Derived | `CASE WHEN LEN(ProcedureCode_Derived)=0 THEN CPTCODE WHEN ProcedureCode_Derived IS NULL THEN CPTCODE ELSE ProcedureCode_Derived END` | Falls back to CPTCODE |
| ProcedureCodeType | '' (empty string) | Not available |
| CPTDescription | CPTCodeDesc | Different column name in source |
| DRGType | '' (empty string) | Not available |
| AllowedAmount | AllowedAmt | Different column name in source |
| ServiceType | '' (empty string) | Not available |
| ScopeDetail | '' (empty string) | Not available |
| PlaceOfService_Derived | POS | Different column name in source |
| RiskType | (direct) | Available |
| Taxonomy_Derived | '' (empty string) | Not available |
| TaxonomyDesc_Derived | '' (empty string) | Not available |
| AdmitType_DERIVED | '' (empty string) | Not available |
| claimnumberlinecpt | '' (empty string) | Not available |
| memdos | `CONCAT(memberid, DateOfService)` | Computed dynamically |
| memmon | `CONCAT(memberid, monthofservice)` | Computed dynamically |
| NDCNumber | '' (empty string) | Not available |
| Period | '' (empty string) | Not available |
| Rowid | `CAST(ROWID AS VARCHAR(500))` | Cast to VARCHAR |

### Special Filters
- **Claims**: `WHERE SubLineOfBusiness != 'Pending/Null'`
- **Membership**: `WHERE SubLineOfBusiness != 'Pending/Null'`; nchmarket='', Period=''

### Special Processing (Post-Union)
CountyCare has the most extensive post-union enrichment:
1. **ConditionCategory**: Extra CountyCare-specific passes matching on ClaimNumber+ClaimLine (without Rowid) for cases where standard matching fails
2. **Service hierarchy enrichment**: Multiple UPDATE passes using:
   - `Contract.MSTR.CPT_Curr` (on ProcedureCode_Derived, ServiceCodeRank=1)
   - `EDW.Analytics.VwMasterUnvClaimLine` (on ClaimNumber+ClaimLine, HealthPlan='countycare') — for empty, NULL, or comma-containing ProcedureCode_Derived values
3. **Updates ServiceLine, ServiceClass, ServiceCategory, ServiceDetail, ServiceType, ServiceSubCategory, ProcedureCode_Derived** where originals are missing

---

## FLBlue
**Stored Procedure:** `dbo.FLBlueOnco_Proc`  
**Claims Table:** `DBO.FLBOncoClaims` (from `##FinalPull_FLBOnco`)  
**Membership Table:** `DBO.FLBOncoMembership` (from `##FLBOncoMembership`)  
**Health Plans:** FLBLUE

### Column Mapping Differences
| Union Column | FLB Source | Notes |
|-------------|----------|-------|
| DataSource | '' (empty string) | Not available |
| nchmarket | (direct) | Available |
| ServicingGroupTIN | '' (empty string) | Not available initially |
| ServicingProviderNPI | (direct) | Available |
| AccountType | '' (empty string) | Not available |
| ClaimNumber_NoAdjRev | '' (empty string) | Not available |
| ProcedureCodeType | '' (empty string) | Not available |
| CPTDescription | '' (empty string) | Not available |
| DRGType | '' (empty string) | Not available |
| AllowedUnits | BilledUnits | Different column name |
| ServiceType | '' (empty string) | Not available |
| ScopeDetail | '' (empty string) | Not available |
| Capitated_Claim | '' (empty string) | Not available |
| RiskType | '' (empty string) | Not available |
| Taxonomy_Derived | '' (empty string) | Not available |
| TaxonomyDesc_Derived | '' (empty string) | Not available |
| AdmitType_DERIVED | '' (empty string) | Not available |
| claimnumberlinecpt | '' (empty string) | Not available |
| memdos | `CONCAT(memberid, DateOfService)` | Computed dynamically |
| memmon | `CONCAT(memberid, monthofservice)` | Computed dynamically |
| NDCNumber | '' (empty string) | Not available |
| Period | '' (empty string) | Not available |

### Special Filters
- **Membership**: `SubLineOfBusiness IS NULL` rows are deleted from AllPayers_OncoMem

### Special Processing (Post-Union)
1. **ServicingGroupTIN enrichment**: Populated via:
   ```
   EDW.Fact.Unv_ClaimLine (on Rowid+ClaimNumber+ClaimLine)
   → EDW.Analytics.VwMasterUnvClaimLine (on Unv_ClaimLineSK, WHERE ServicingProviderGroupTIN != 'NA')
   ```
   Only for `HEALTHPLAN IN ('FLBLUE')`

2. **ServicingGroupName enrichment**: Populated via:
   ```
   EDW.MSTR.OrganizationMaster_Curr (on NPI)
   → ISNULL(OrganizationName, OrganizationOtherName)
   ```
   Only for `HealthPlan = 'FLBLUE'`

---

## Highmark
**Stored Procedure:** None documented  
**Claims Table:** `DBO.HIGGHSALKDFJLASK` (appears to be a placeholder/typo table name)  
**Membership Table:** `DBO.hIGHMARK_MEM`  
**Health Plans:** HIGHMARK

### Column Mapping
Claims follow the Molina-like full schema (same as the standard columns). Membership uses UNION (not UNION ALL) with the same empty-string mappings as CC/FLB for nchmarket and Period.

### Key Notes
- The claims source table name `HIGGHSALKDFJLASK` appears to be a placeholder — this may need updating
- Highmark membership uses `UNION` (deduplication) rather than `UNION ALL`
- All other columns map similarly to Molina's full-fidelity pattern

---

## Summary Comparison Matrix

| Feature | Molina | Legacy | CountyCare | FLBlue | Highmark |
|---------|--------|--------|-----------|--------|---------|
| DataSource | ✅ | ✅ | ✅ | ❌ (empty) | ✅ |
| ServicingGroupTIN | ✅ | ✅ | ❌ (empty) | ❌→enriched | ✅ |
| ServicingProviderName | ✅ | GroupName alias | ProviderName fallback | ✅ | ✅ |
| ServicingProviderNPI | ✅ | ✅ | ❌ (empty) | ✅ | ✅ |
| AccountType | ✅ | ✅ | ❌ (empty) | ❌ (empty) | ❌ (empty) |
| ProcedureCode_Derived | ✅ | ✅ | CPTCODE fallback | ✅ | ✅ |
| AllowedUnits source | AllowedUnits | AllowedUnits | AllowedUnits | BilledUnits | AllowedUnits |
| AllowedAmount source | AllowedAmount | AllowedAmount | AllowedAmt | AllowedAmount | AllowedAmount |
| memdos/memmon | From proc | From proc | CONCAT() | CONCAT() | From proc |
| Membership UNION type | UNION ALL | UNION ALL | UNION ALL | UNION ALL | UNION |
| SubLOB filter | None | None | !=Pending/Null | NULL deleted | None |
| SIMPLY exclusion | N/A | Membership only | N/A | N/A | N/A |
| Post-union enrichment | MMP dedup | membershipkey fix | Service hierarchy, ConditionCategory | TIN, GroupName | None |
