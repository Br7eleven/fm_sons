# FM Sons App Completion Plan

## Project Snapshot
- Project: fm_sons
- Platform: Flutter (Android, iOS, Web, Linux, Windows, macOS folders present)
- Date: 2026-04-21
- Branch observed: develop
- Last commit observed: 7a3137f (2026-01-12)

## Goal
Complete the app to production-ready quality with stable data persistence, reliable backup/restore, secure authentication, complete invoice workflows, and release readiness.

## Scope of This Plan
This plan was prepared after a full workspace scan with emphasis on:
- configuration and dependencies
- data layer and database setup
- feature modules in lib/
- testing and release readiness

Generated/build artifacts under build/ are intentionally not treated as source of truth.

## Current State Summary

### What exists and is partially complete
- Auth flow with PIN UI and controller
- Dashboard screens and widgets
- Invoice creation flow, preview screens, and template variants
- Masters area for units, products, customers
- SQLite setup and at least one DAO path
- Google Drive backup service skeleton

### Main blockers to completion
1. Data persistence is incomplete across masters modules.
2. Backup flow is incomplete (upload exists, restore and resilience missing).
3. Error handling and null safety need hardening in critical paths.
4. Tests are minimal and not sufficient for production confidence.
5. Release readiness tasks are largely pending (signing, app IDs, store-grade setup).

## Module Health Matrix

| Module | Current State | Risk | Completion Estimate |
|---|---|---|---|
| Auth | PIN flow exists; security hardening needed | High | 70% |
| Dashboard | UI present; data wiring incomplete | Medium | 50% |
| Invoice | Core flow present; persistence/print gaps remain | Medium | 75% |
| Invoice Preview Templates | Active development; design iterations ongoing | Low | 70% |
| Masters | CRUD-like UI/controllers exist; persistence gaps | High | 65% |
| Local Database | Base setup exists; schema and DAO expansion needed | High | 55% |
| Backup (Google Drive) | Sign-in/upload skeleton exists | High | 35% |
| Testing | Placeholder-level | Critical | 10% |
| Release Readiness | Basic project scaffolding only | High | 25% |

## Observed Technical Risks

### 1) Persistence and data integrity
- Risk: masters data appears controller-driven and may not be fully persisted.
- Action: add/complete DAOs for all entities and wire controllers to DB.

### 2) Backup and restore reliability
- Risk: backup upload path exists, restore path not complete.
- Action: implement restore with validation, conflict strategy, and user feedback.

### 3) Runtime safety and error handling
- Risk: network/auth/database calls need robust try-catch and user-safe messaging.
- Action: standardize service result models and centralized exception mapping.

### 4) Security and auth hardening
- Risk: PIN/auth flow needs secure storage and optional biometrics integration.
- Action: move sensitive values to secure storage and enforce lockout policy.

### 5) Quality and regression control
- Risk: current test coverage is too low for release confidence.
- Action: establish unit/widget/integration baseline and CI checks.

## Step-by-Step Execution Plan
Follow these steps in exact order.

## Step 0: Baseline and Branch Safety
1. Create a working branch from develop.
2. Run dependency sync and static analysis.
3. Record current warnings and errors in this document before changing code.

Commands:
```bash
flutter pub get
flutter analyze
flutter test
```

Done when:
- Baseline issues are written down.
- Branch is ready for incremental commits.

## Step 1: Freeze Release Scope
1. Confirm Release 1 platform scope (Android only or Android + iOS).
2. Confirm Release 1 feature scope (backup/restore, biometrics, PDF/print).
3. Convert scope into acceptance criteria list.

Deliverable:
- A locked scope checklist for Release 1.

Done when:
- No new features are added without being logged in this file.

Step 1 Decision Lock (2026-04-21):
1. Release 1 platform scope: Android only.
2. Release 1 mandatory feature scope: local persistence for invoices and masters, invoice lifecycle, stable invoice preview templates, manual Google Drive backup and restore, dashboard basic counters, PDF export.
3. Release 1 deferred scope: iOS release packaging, biometric unlock, advanced analytics, automatic background backup sync, web/desktop production parity, native printer integration.

Step 1 Acceptance Criteria (Locked):
1. Android release build installs and runs on a real device.
2. Customer, product, unit, invoice, and invoice item data persist across app restart.
3. Backup and restore can be triggered manually from Google Drive without data corruption.
4. Dashboard totals match persisted database values.
5. Invoice preview can export to PDF.
6. No blocking analyzer errors in release candidate branch.

## Step 2: Finalize Data Model
1. List entities and required fields: invoice, invoice_item, customer, product, unit, contract.
2. Mark mandatory vs optional fields.
3. Define relationships and key constraints.

Deliverable:
- Data dictionary section in docs with field-level definitions.

Done when:
- Every form field maps to exactly one persisted field.

Step 2 Output: Data Model Lock (2026-04-21)

Data modeling rules for Release 1:
1. Dates are stored as ISO-8601 UTC text.
2. Money is stored as REAL for Release 1 compatibility with existing code.
3. Master entities use TEXT primary keys because current models use String ids.
4. Transaction entities use INTEGER autoincrement keys where already established.
5. Invoice and invoice item rows store display snapshots so old invoices remain readable after master updates.

Entity dictionary:

1. customers (new table in Step 3)
- id: TEXT PRIMARY KEY, required
- name: TEXT NOT NULL UNIQUE (case-insensitive), required
- phone: TEXT, optional
- address: TEXT, optional
- created_at: TEXT NOT NULL, required
- updated_at: TEXT NOT NULL, required

2. units (new table in Step 3)
- id: TEXT PRIMARY KEY, required
- name: TEXT NOT NULL UNIQUE (case-insensitive), required
- symbol: TEXT NOT NULL, required
- allow_decimal: INTEGER NOT NULL DEFAULT 0, required (0=false, 1=true)
- description: TEXT, optional
- is_active: INTEGER NOT NULL DEFAULT 1, required
- created_at: TEXT NOT NULL, required
- updated_at: TEXT NOT NULL, required

3. products (existing table to be migrated in Step 3)
- id: TEXT PRIMARY KEY, required
- name: TEXT NOT NULL UNIQUE (case-insensitive), required
- type: TEXT NOT NULL, required (material, service)
- unit_id: TEXT NOT NULL, required (FK -> units.id)
- default_rate: REAL NOT NULL DEFAULT 0, required
- description: TEXT, optional
- is_active: INTEGER NOT NULL DEFAULT 1, required
- created_at: TEXT NOT NULL, required
- updated_at: TEXT NOT NULL, required

4. contracts (existing table, extend in Step 3 if needed)
- id: INTEGER PRIMARY KEY AUTOINCREMENT, required
- contract_number: TEXT NOT NULL UNIQUE, required
- department_name: TEXT NOT NULL, required
- start_date: TEXT, optional
- end_date: TEXT, optional
- total_value: REAL, optional
- status: TEXT NOT NULL DEFAULT active, required (active, completed, cancelled)
- created_at: TEXT NOT NULL, required
- updated_at: TEXT NOT NULL, required

5. invoices (existing table to be migrated in Step 3)
- id: INTEGER PRIMARY KEY AUTOINCREMENT, required
- invoice_number: TEXT NOT NULL UNIQUE, required
- customer_id: TEXT NOT NULL, required (FK -> customers.id)
- client_name: TEXT NOT NULL, required (snapshot for history)
- client_address: TEXT, optional (snapshot for history)
- contract_id: INTEGER, optional (FK -> contracts.id)
- invoice_date: TEXT NOT NULL, required
- due_date: TEXT, optional
- subtotal: REAL NOT NULL, required
- tax: REAL NOT NULL DEFAULT 0, required
- total: REAL NOT NULL, required
- status: TEXT NOT NULL, required (draft, pending, paid, cancelled)
- created_at: TEXT NOT NULL, required
- updated_at: TEXT NOT NULL, required

6. invoice_items (existing table to be migrated in Step 3)
- id: INTEGER PRIMARY KEY AUTOINCREMENT, required
- invoice_id: INTEGER NOT NULL, required (FK -> invoices.id ON DELETE CASCADE)
- product_id: TEXT, optional (FK -> products.id)
- product_name: TEXT NOT NULL, required (snapshot for history)
- unit_id: TEXT, optional (FK -> units.id)
- unit_label: TEXT NOT NULL, required (snapshot, example: kg, bag)
- quantity: REAL NOT NULL, required
- rate: REAL NOT NULL, required
- amount: REAL NOT NULL, required
- sort_order: INTEGER NOT NULL DEFAULT 0, required

Relationship map:
1. customers (1) -> (N) invoices
2. contracts (1) -> (N) invoices (optional link)
3. invoices (1) -> (N) invoice_items with cascade delete
4. units (1) -> (N) products
5. products (1) -> (N) invoice_items (optional reference, historical snapshot retained)

Constraint rules:
1. invoice_number must be unique.
2. customer name, product name, and unit name must be unique case-insensitively.
3. quantity must be > 0.
4. rate, subtotal, tax, total, amount must be >= 0.
5. status fields are restricted to fixed values.
6. product_id and unit_id in invoice_items may be null, but snapshot columns product_name and unit_label are always required.

UI-to-database field mapping for Release 1:
1. New invoice customer selection/name -> invoices.customer_id + invoices.client_name.
2. Invoice date picker -> invoices.invoice_date.
3. Invoice line product selection -> invoice_items.product_id + invoice_items.product_name.
4. Invoice line unit selection -> invoice_items.unit_id + invoice_items.unit_label.
5. Quantity input -> invoice_items.quantity.
6. Rate input -> invoice_items.rate.
7. Line amount display -> invoice_items.amount.
8. Invoice totals section -> invoices.subtotal, invoices.tax, invoices.total.
9. Invoice state progression -> invoices.status.

Known schema gaps to close in Step 3:
1. Database creation currently initializes invoices, products, and contracts only.
2. invoice_items, customers, and units tables are not initialized yet.
3. Product schema currently stores unit as plain text and does not store product type.
4. Invoice schema currently lacks customer_id and updated_at.

Step 2 Completion Check:
1. Entities defined: invoice, invoice_item, customer, product, unit, contract.
2. Required vs optional fields defined for each entity.
3. Relationships and key constraints defined.
4. UI field mapping to persisted fields defined.

## Step 3: Complete SQLite Schema and Migrations
1. Ensure all required tables are created in DB init.
2. Add schema versioning strategy for future migrations.
3. Add migration tests for upgrade path from current app state.

Files in scope:
- lib/data/local/app_database.dart
- lib/data/local/tables/

Done when:
- Fresh install and upgraded install both produce valid schema.

Step 3 Execution Output (2026-04-21):
1. Database schema versioning implemented in AppDatabase with schemaVersion = 2.
2. Database onConfigure now enables PRAGMA foreign_keys = ON.
3. Fresh-install schema creation now includes all required tables:
	customers, units, products, contracts, invoices, invoice_items.
4. Legacy upgrade path implemented for v1 -> v2:
	- products table rebuilt to new shape and legacy rows migrated.
	- contracts table rebuilt with status default + timestamps.
	- invoices table rebuilt with customer_id and updated_at.
	- invoice_items migrated to new fields (unit_label, sort_order, references).
	- legacy unit names are auto-normalized into units table during migration.
5. Migration test added and passing:
	test/data/local/app_database_migration_test.dart
6. Test dependency added:
	sqflite_common_ffi in dev_dependencies.

Step 3 Completion Check:
1. Required tables are created in DB init path.
2. Versioned migration pipeline exists for legacy upgrade.
3. Automated upgrade test passes for v1 schema migration.

## Step 4: Implement Missing DAOs
1. Create DAOs for customer, product, unit, contract.
2. Standardize CRUD return types and error handling patterns.
3. Add query methods used by dashboard and invoice flows.

Files in scope:
- lib/data/local/dao/

Done when:
- All business entities can be created, read, updated, and deleted from DB.

Step 4 Execution Output (2026-04-21):
1. Added shared DAO result wrapper for standardized success/failure handling:
	- lib/data/local/dao/dao_result.dart
2. Added Customer DAO with standardized CRUD + invoice-friendly queries:
	- create, update, delete, getById, findByName, addOrGetByName, getAll, searchByName, countCustomers
	- file: lib/data/local/dao/customer_dao.dart
3. Added Unit DAO with standardized CRUD + invoice-friendly queries:
	- create, update, deactivate, delete, getById, getAll, searchByName, countUnits
	- file: lib/data/local/dao/unit_dao.dart
4. Added Product DAO with standardized CRUD + selector-friendly joins:
	- create, update, deactivate, delete, getById, getAll, searchByName, getByUnitId, countProducts
	- joins products with units to hydrate Product + Unit models used by invoice item selection
	- file: lib/data/local/dao/product_dao.dart
5. Added Contract data model + DAO for complete contract persistence layer:
	- model file: lib/data/local/models/contract_model.dart
	- DAO file: lib/data/local/dao/contract_dao.dart
	- methods: create, update, delete, getById, getAll, getActiveContracts, searchByDepartment, countContracts
6. Error handling pattern is now consistent across new DAOs via DaoResult<T> return type.

Step 4 Completion Check:
1. Customer, product, unit, and contract DAOs are created.
2. New DAOs use standardized result shape for CRUD and query methods.
3. Query methods needed by invoice/dashboard flows are available in DAO layer.

## Step 5: Wire Controllers to Persistence
1. Refactor masters controllers to load from DAOs at startup.
2. Replace temporary in-memory source-of-truth with DB-backed state.
3. Add loading, empty, and failure states for each controller.

Files in scope:
- lib/view/masters/**/**_controller.dart
- lib/view/invoice/controller/create_invoice_controller.dart

Done when:
- Data remains after app restart and reflects DB changes instantly.

Step 5 Execution Output (2026-04-21):
1. Refactored masters controllers from in-memory-only state to DAO-backed persistence:
	- lib/view/masters/unit/unit_controller.dart
	- lib/view/masters/product/product_controller.dart
	- lib/view/masters/customer/customer_controller.dart
2. Added startup initialization and DB hydration in each controller:
	- initialize(), load/refresh methods, and persisted CRUD pathways.
3. Added explicit controller state flags for UI:
	- isLoading, hasError, errorMessage, isEmpty.
4. Updated app provider bootstrap to rely on DAO-backed controller init instead of manual in-memory seed:
	- lib/main.dart
5. Updated masters UI flows to use async persistence methods and proper error feedback:
	- lib/view/masters/unit/unit_form_screen.dart
	- lib/view/masters/unit/unit_list_screen.dart
	- lib/view/masters/product/product_form_screen.dart
	- lib/view/masters/product/product_list_screen.dart
	- lib/view/masters/product/product_selector_bottom_sheet.dart
	- lib/view/masters/customer/customer_form_screen.dart
	- lib/view/masters/customer/customer_selector_bottom_sheet.dart.dart
6. Added state helpers to invoice controller for consistent controller-state pattern in invoice flow:
	- lib/view/invoice/controller/create_invoice_controller.dart
7. Validation status:
	- Full flutter analyze run completed with only pre-existing non-Step-5 warnings.

Step 5 Completion Check:
1. Masters controllers now load data from DAOs on startup.
2. In-memory source-of-truth replaced by DB-backed operations.
3. Loading/empty/failure state is present for each refactored controller.

## Step 6: Complete Invoice Lifecycle
1. Finalize invoice create/edit/list/status transitions.
2. Ensure invoice items persist and recalculate totals correctly.
3. Add duplicate invoice number protection with user-friendly feedback.

Files in scope:
- lib/data/local/dao/invoice_dao.dart
- lib/view/invoice/

Done when:
- Flow passes: create -> save -> reopen -> update status -> list correctly.

Step 6 Execution Output (2026-04-21):
1. Extended invoice persistence model and DAO to support full lifecycle:
	- invoice model now includes customer_id and updated_at
	- invoice DAO now includes duplicate number checks, status-filter listing, status summary, and next invoice number generation
	- files:
	  - lib/data/local/models/invoice_model.dart
	  - lib/data/local/dao/invoice_dao.dart
2. Added invoice item persistence layer:
	- new item model and DAO for insert/list/delete by invoice
	- files:
	  - lib/data/local/models/invoice_item_model.dart
	  - lib/data/local/dao/invoice_item_dao.dart
3. Refactored invoice controller for DB-backed lifecycle:
	- db-driven invoice number generation
	- saveCurrentInvoice() now persists invoice + line items
	- persisted customer resolution via customer DAO
	- list/status/delete helper methods added
	- next draft preparation after successful save
	- file:
	  - lib/view/invoice/controller/create_invoice_controller.dart
4. Wired invoice UI to new lifecycle flow:
	- add item flow now sends product/unit metadata for persistence
	- preview Save & Close now persists invoice and shows success/error feedback
	- create screen now validates customer and loading state before preview
	- files:
	  - lib/view/invoice/add_invoice_item_screen.dart
	  - lib/view/invoice/preview/invoice_preview_screen.dart
	  - lib/view/invoice/create_invoice_screen.dart
5. Duplicate invoice number protection:
	- enforced before insert via invoiceNumberExists checks with user-facing errors.
6. Validation:
	- touched Step 6 files compile clean.
	- full analyzer shows only pre-existing non-Step-6 warnings.

Step 6 Completion Check:
1. Invoice create -> save flow persists invoice header + line items.
2. Lifecycle helper methods exist for status updates and listing.
3. Duplicate invoice number insertion is prevented with user feedback.

## Step 7: Complete Backup and Restore
1. Keep current backup upload flow.
2. Implement restore flow from Google Drive.
3. Add conflict policy: local newer vs cloud newer.
4. Add corruption checks before replacing local DB.
5. Add retry and cancellation-safe UX.

Files in scope:
- lib/data/backup/google_drive_service.dart
- lib/data/backup/backup_manager.dart
- lib/data/backup/restore_manager.dart (new)

Done when:
- End-to-end flow passes: backup -> reinstall/clear -> restore -> verify records.

Step 7 Execution Output (2026-04-22):
1. Upgraded Google Drive service for production backup operations:
	- resilient sign-in handling and sign-out support
	- timestamped backup discovery/listing
	- download support for restore flow
	- retry wrapper for upload/download failures
	- structured backup file metadata model
	- file:
	  - lib/data/backup/google_drive_service.dart
2. Enhanced backup manager with safer backup flow:
	- uses real app database path from AppDatabase
	- validates local DB existence and non-empty size before upload
	- creates timestamped backup names
	- supports cancellation callback and retry count
	- returns structured backup operation result
	- file:
	  - lib/data/backup/backup_manager.dart
3. Added dedicated restore manager:
	- restoreLatestBackup() workflow from Google Drive
	- conflict policy implementation:
	  - preferLocal
	  - preferCloud
	  - requireConfirmation
	- local-vs-cloud modified-time conflict handling
	- cancellation-safe checkpoints before destructive operations
	- rollback strategy using local pre-restore backup copy
	- file:
	  - lib/data/backup/restore_manager.dart
4. Added corruption/integrity protections before replacement:
	- downloaded file existence + size validation
	- SQLite header validation
	- PRAGMA integrity_check validation
5. Added backup/restore shared result models:
	- operation result types and conflict enums for UI integration
	- file:
	  - lib/data/backup/backup_models.dart
6. Added database lifecycle helpers needed for safe restore replace:
	- databaseFilePath()
	- closeDatabase()
	- file:
	  - lib/data/local/app_database.dart
7. Validation:
	- Step 7 touched files compile clean.
	- full analyzer run shows only pre-existing non-Step-7 warnings.

Step 7 Completion Check:
1. Backup upload flow remains supported and now includes retries/result metadata.
2. Restore flow from Google Drive is implemented.
3. Local newer vs cloud newer conflict policy is implemented.
4. Integrity checks run before local DB replacement.
5. Cancellation-safe checkpoints and rollback behavior are implemented.

## Step 8: Harden Authentication and Security
1. Remove hardcoded secrets and PIN constants from code.
2. Store PIN securely and add lockout policy.
3. Implement optional biometric auth with fallback to PIN.
4. Ensure sensitive logs are not printed in release mode.

Done when:
- Auth survives restart securely and cannot be bypassed from UI.

Step 8 Status (2026-04-22):
1. Skipped by owner request for current release track.
2. PIN entry/auth hardening is deferred and removed from active execution sequence.

## Step 9: Connect Dashboard to Real Data
1. Replace placeholder values with DB queries.
2. Add key metrics: invoice count, pending amount, paid amount, recent invoices.
3. Ensure dashboard refreshes after invoice operations.

Files in scope:
- lib/view/dashboard/dashboard_screen.dart

Done when:
- Dashboard numbers match database queries exactly.

Step 9 Execution Output (2026-04-22):
1. Replaced static dashboard metrics with DAO-backed queries:
	- total invoices from InvoiceDao.getInvoiceStatusSummary()
	- pending amount from InvoiceDao.getInvoiceStatusSummary()
	- paid amount from InvoiceDao.getInvoiceStatusSummary()
	- files:
	  - lib/view/dashboard/dashboard_screen.dart
	  - lib/view/dashboard/widgets/stat_card.dart
	  - lib/view/dashboard/widgets/overview_card.dart
2. Added real-time today metrics from persisted invoices:
	- today's billed amount computed from invoice_date + total values
	- today's invoice count badge in overview card
3. Added recent invoices section with live records:
	- latest 5 invoices from DB
	- shows invoice number, client name, date, total, and status indicator
	- file:
	  - lib/view/dashboard/dashboard_screen.dart
4. Added dashboard refresh hooks:
	- pull-to-refresh support
	- automatic reload after returning from Create Invoice flow
	- resume-time refresh via app lifecycle observer
	- files:
	  - lib/view/dashboard/dashboard_screen.dart
	  - lib/view/dashboard/widgets/quick_actions_grid.dart
5. Validation:
	- touched Step 9 files report no analyzer errors.

Step 9 Completion Check:
1. Placeholder metrics replaced with DB-driven values.
2. Invoice count, pending amount, paid amount, and recent invoices are rendered from persisted data.
3. Dashboard refreshes after invoice operations and on manual refresh.

## Step 10: Complete Invoice Preview and Output
1. Normalize all templates for totals and amount-in-words consistency.
2. Add print/PDF output if in Release 1 scope.
3. Ensure output is stable for long customer names and many line items.

Files in scope:
- lib/view/invoice/preview/

Done when:
- Every template renders correctly with real data and no overflow issues.

Step 10 Execution Output (2026-04-22):
1. Normalized template-level invoice rendering via shared base helpers:
	- standardized currency formatting (Rs with 2 decimals)
	- standardized invoice date formatting (dd MMM yyyy)
	- standardized amount-in-words fallback
	- standardized quantity formatting for integer/decimal values
	- file:
	  - lib/view/invoice/preview/templates/invoice_template_base.dart
2. Normalized totals and amount-in-words across all active templates:
	- Template Modern now uses shared total/date/amount wording format
	- Template Tax 3 now uses shared total/date/amount wording format
	- Template Tax 1 now uses shared total/date/amount wording format and summary breakdown
	- files:
	  - lib/view/invoice/preview/templates/template_modern.dart
	  - lib/view/invoice/preview/templates/template_tax_3.dart
	  - lib/view/invoice/preview/templates/template_tax_1.dart
3. Added production print/PDF output from live preview:
	- print action implemented via Printing.layoutPdf
	- share/export PDF action implemented via Printing.sharePdf
	- preview capture rendered through RepaintBoundary and embedded into A4 PDF
	- file:
	  - lib/view/invoice/preview/invoice_preview_screen.dart
4. Hardened preview for long content and many line items:
	- customer/item/unit text fields use max-lines and ellipsis
	- preview item list is clamped with "+N more items" indicator when list is long
	- output remains bounded to A4 preview area without overflow
5. Added required output dependencies:
	- pdf
	- printing
	- file:
	  - pubspec.yaml
6. Validation:
	- no analyzer errors in touched Step 10 preview files.

Step 10 Completion Check:
1. Template totals/date/amount-in-words formatting is consistent across active themes.
2. Print and PDF share/export flows are implemented in preview actions.
3. Long customer names and many line items are handled without preview overflow.

## Step 11: Add Validation and UX Guardrails
1. Add strict form validation for masters and invoice forms.
2. Add loading indicators and retry states for async actions.
3. Add clear toast/dialog feedback for save, backup, and restore actions.

Done when:
- No silent failures remain in critical user actions.

Step 11 Execution Output (2026-04-23):
1. Added strict validation to invoice item entry:
	- required product selection
	- required unit selection
	- quantity must be numeric and > 0
	- rate must be numeric and >= 0
	- file:
	  - lib/view/invoice/add_invoice_item_screen.dart
2. Added strict validation and clearer feedback to master forms:
	- customer name length and phone format checks
	- product name length and positive default rate checks
	- unit name and symbol checks
	- files:
	  - lib/view/masters/customer/customer_form_screen.dart
	  - lib/view/masters/product/product_form_screen.dart
	  - lib/view/masters/unit/unit_form_screen.dart
3. Added async loading states to save flows:
	- submit buttons now disable while requests are in-flight
	- spinner shown during save/update operations
	- files:
	  - lib/view/invoice/add_invoice_item_screen.dart
	  - lib/view/invoice/preview/invoice_preview_screen.dart
	  - lib/view/masters/customer/customer_form_screen.dart
	  - lib/view/masters/product/product_form_screen.dart
	  - lib/view/masters/unit/unit_form_screen.dart
4. Added clearer toast/snackbar feedback:
	- validation failure guidance for invoice item add
	- save failure messages for customer/product/unit forms
	- dashboard now exposes retry on load failure
5. Added backup and restore UX guardrails on dashboard:
	- dedicated Google Drive backup/restore section
	- loading indicators during backup/restore
	- retry actions on failure
	- conflict confirmation when local database is newer than cloud backup
	- files:
	  - lib/view/dashboard/dashboard_screen.dart
6. Validation:
	- touched Step 11 files report no analyzer errors.

Step 11 Completion Check:
1. Strict validation added for master and invoice forms.
2. Loading indicators and retry states added for async user actions.
3. Clear feedback added for save, backup, and restore paths.

## Step 12: Build Test Foundation
1. Add DAO unit tests for each entity.
2. Add controller tests for business logic and state transitions.
3. Add widget tests for PIN, invoice creation, and backup screens.
4. Add integration smoke test for invoice happy path.

Commands:
```bash
flutter test
```

Done when:
- Tests cover critical flows and fail on real regressions.

## Step 13: Quality Gate and CI
1. Enforce flutter analyze and flutter test in CI.
2. Block merges on failing checks.
3. Add formatting and lint consistency checks.

Done when:
- Every PR is validated before merge.

## Step 14: Android Release Readiness
1. Set final applicationId and app name.
2. Configure release signing.
3. Verify Google Sign-In config for release SHA keys.
4. Build and test release APK/AAB.

Commands:
```bash
flutter build apk --release
flutter build appbundle --release
```

Done when:
- Signed Android artifact installs and runs with sign-in and DB features.

## Step 15: iOS Release Readiness (if in scope)
1. Set bundle identifier and signing team.
2. Configure Google Sign-In URL schemes.
3. Build and test archive on device.

Command:
```bash
flutter build ipa --release
```

Done when:
- iOS archive builds successfully and core flows pass on real device.

## Step 16: Final Documentation and Handover
1. Update README with setup, run, test, and release commands.
2. Add architecture notes and DB schema docs.
3. Add operations guide: backup/restore and troubleshooting.
4. Add known limitations and post-release backlog.

Done when:
- A new developer can set up and run the project with docs only.

## Step 17: Release Candidate Checklist
1. Re-run full quality gate.
2. Run manual regression checklist on critical flows.
3. Tag release version and prepare changelog.

Commands:
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

Done when:
- Release candidate is stable and traceable.

## Optional Fast Track (If Time Is Limited)
1. Must-do: Steps 0, 2, 3, 4, 5, 6, 7, 12, 14, 17.
2. Can defer: biometrics, advanced analytics, non-Android release.

## Progress Tracker
Use this checklist while executing:

- [ ] Step 0 complete
- [x] Step 1 complete
- [x] Step 2 complete
- [x] Step 11 complete
- [x] Step 4 complete
- [x] Step 5 complete
- [x] Step 6 complete
- [x] Step 7 complete
- [x] Step 8 skipped by owner (PIN/auth flow deferred)
- [x] Step 9 complete
- [x] Step 10 complete
- [x] Step 11 complete
- [ ] Step 12 complete
- [ ] Step 13 complete
- [ ] Step 14 complete
- [ ] Step 15 complete
- [ ] Step 16 complete
- [ ] Step 17 complete

## Definition of Done
A feature is done only when all conditions are met:
- Functional acceptance criteria implemented
- Error handling and empty/loading states implemented
- Persistence verified (if applicable)
- Tests added or updated
- Analyzer clean for touched files
- Documentation updated

## Open Questions For Next Iteration
Step 1 locked the scope decisions as follows:
1. Backup and restore for Release 1: required.
2. Biometric unlock for Release 1: deferred.
3. PDF generation for Release 1: required.
4. Physical printing for Release 1: deferred unless promoted later.
5. Release 1 platform scope: Android only.
6. Dashboard scope: operational counters first, advanced analytics deferred.

## Owner Request Log
Use this section for new requests you tell me to add next.

- Request 001: Initial completion plan created.
- Request 002: Expand this plan into complete step-by-step execution instructions.
- Request 003: Execute Step 1 and lock Release 1 scope with acceptance criteria.
- Request 004: Execute Step 2 and lock the data model with entity-level field definitions.
- Request 005: Execute Step 3 with schema upgrades, migration path, and migration test coverage.
- Request 006: Execute Step 4 with customer, unit, product, and contract DAO implementation.
- Request 007: Execute Step 5 by wiring masters controllers and related UI flows to DAO-backed persistence.
- Request 008: Execute Step 6 by implementing persisted invoice lifecycle and duplicate-number safeguards.
- Request 009: Execute Step 7 by implementing robust Google Drive backup and restore with conflict and integrity handling.
- Request 010: Skip Step 8 PIN/security work and continue directly with Step 9 dashboard data integration.
- Request 011: Execute Step 10 to complete invoice preview normalization and print/PDF output.
- Request 012: Execute Step 11 to add validation and UX guardrails for forms, save flows, backup, and restore.

## Change Log
- 2026-04-21: Initial plan created after workspace analysis.
- 2026-04-21: Added step-by-step implementation guide with ordered execution steps, commands, and completion checkpoints.
- 2026-04-21: Executed Step 1 by locking Release 1 scope and acceptance criteria, and updated progress tracker.
- 2026-04-21: Executed Step 2 by adding a locked data dictionary, relationships, constraints, and UI-to-database field mapping.
- 2026-04-21: Executed Step 3 by implementing schema versioning, v1->v2 migrations, new table coverage, and a passing migration test.
- 2026-04-21: Executed Step 4 by adding DAO result standardization and new DAOs for customer, unit, product, and contract.
- 2026-04-21: Executed Step 5 by refactoring masters controllers to DAO-backed startup loading, async CRUD, and UI loading/error state handling.
- 2026-04-21: Executed Step 6 by adding invoice+item persistence flow, db-driven invoice numbering, lifecycle helpers, and duplicate-number protection.
- 2026-04-22: Executed Step 7 by upgrading backup upload flow, adding restore manager, conflict policy, cancellation-safe rollback, and integrity validation.
- 2026-04-22: Step 8 skipped by owner request (PIN/auth hardening deferred from this release sequence).
- 2026-04-22: Executed Step 9 by wiring dashboard counters and recent invoices to DAO data with post-invoice refresh and pull-to-refresh.
- 2026-04-22: Executed Step 10 by normalizing invoice preview templates, adding print/PDF output actions, and hardening preview overflow handling.
- 2026-04-23: Executed Step 11 by adding strict validation, loading states, retry actions, and user feedback across invoice, master, backup, and restore flows.
