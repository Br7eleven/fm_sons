# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FM Sons is a Flutter-based billing/invoicing application with SQLite persistence and Google Drive backup capabilities. The app manages customers, products, units, contracts, and invoices with PDF generation for invoice templates.

**Platform Support**: Android, iOS, Linux, macOS, Windows, Web (multi-platform scaffolding present)

**Primary Branch**: `main` (development work occurs on `develop`)

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (default device)
flutter run

# Run with specific device
flutter devices
flutter run -d <device-id>

# Run static analysis
flutter analyze

# Run tests
flutter test

# Build for Android
flutter build apk
flutter build appbundle

# Clean build artifacts
flutter clean && flutter pub get
```

## Architecture Overview

### State Management
The app uses **Provider** for state management. All controllers extend `ChangeNotifier` and are registered in `main.dart`:
- `InvoiceController` - manages invoice creation, items, and drafts
- `UnitController` - manages measurement units
- `ProductController` - depends on `UnitController` for unit references
- `CustomerController` - manages customer master data

**Important**: `ProductController` has a dependency on `UnitController` that must be maintained during provider registration.

### Data Layer Structure

**Database**: SQLite with `sqflite` package
- Schema version managed in `AppDatabase.schemaVersion`
- Current version: 2
- Foreign keys are enabled via `PRAGMA foreign_keys = ON`

**Migration Strategy**: The app uses a versioned migration system in `app_database.dart`. When adding schema changes:
1. Increment `schemaVersion` constant
2. Add new migration block in `_runMigrations()`
3. Legacy data is preserved with fallback values during migrations

**Tables** (defined in `lib/data/local/tables/`):
- `customers` - customer master with GSTIN/PAN
- `units` - measurement units (kg, piece, bag, etc.) with decimal policy
- `products` - materials/items with type and default rates, references `units.id`
- `contracts` - government contracts with department and dates
- `invoices` - invoice headers, references `customers.id` and `contracts.id`
- `invoice_items` - line items, references `invoices.id`, `products.id`, and `units.id`

**Data Access**: Use DAO classes in `lib/data/local/dao/` for all database operations. Do not write raw SQL queries in controllers or UI code.

### Module Organization

```
lib/
├── core/               # Constants and core utilities
├── data/
│   ├── backup/        # Google Drive backup/restore logic
│   └── local/         # SQLite database, tables, DAOs, models
├── utils/             # Helper utilities and constants
└── view/              # UI layer (screens, widgets, controllers)
    ├── auth/          # PIN-based authentication
    ├── dashboard/     # Main dashboard with stats and quick actions
    ├── invoice/       # Invoice creation, preview, PDF templates
    ├── masters/       # Master data CRUD (customer, product, unit)
    ├── settings/      # App settings
    ├── shared/        # Shared widgets (bottom nav, etc.)
    └── splash/        # Splash screen
```

### Invoice Workflow

1. **Creation**: `CreateInvoiceScreen` uses `InvoiceController` to manage state
2. **Items**: Line items are added via `AddInvoiceItemScreen` and stored in controller
3. **Preview**: `InvoicePreviewScreen` renders selected template with data
4. **Templates**: Multiple PDF templates in `lib/view/invoice/preview/templates/`
   - `template_modern.dart` - clean modern design
   - `template_tax_1.dart` - tax-focused layout
   - `template_tax_3.dart` - alternate tax layout
5. **PDF Generation**: Uses `pdf` and `printing` packages

**Template Selection**: Users select template via `ThemeSelector` widget. Template choice persists in controller state.

### Backup System

**Service**: `GoogleDriveService` handles OAuth and file upload/download
**Manager**: `BackupManager` orchestrates database backup operations
**Format**: Database file is uploaded to Google Drive with timestamp naming

**Google Drive Integration**:
- Uses `google_sign_in` for authentication
- Requires `client_secret_*.json` in project root (not committed)
- Scopes needed: Drive file access

## Critical Patterns

### Controller Initialization
Controllers may load data asynchronously during initialization. Always check `_initialized` flag before accessing data:

```dart
if (!_initialized) {
  await initialize();
}
```

### Database Transactions
For multi-step operations (e.g., creating invoice + items), use transactions to ensure atomicity:

```dart
await db.transaction((txn) async {
  // all operations here
});
```

### Foreign Key Constraints
The database enforces referential integrity. When deleting referenced entities:
- Set `ON DELETE CASCADE` for required relationships
- Set `ON DELETE SET NULL` for optional relationships
- Check for references before deletion in UI layer

### Null Safety for Master Data
Legacy migrations may produce null foreign keys (e.g., `invoice.customer_id` can be null). Controllers must handle:
- `invoice.customer_id == null` → display `invoice.client_name` as fallback
- `invoice_item.product_id == null` → display `invoice_item.product_name` as fallback

## Navigation Routes

Defined in `main.dart`:
- `/` → `SplashScreen`
- `/auth` → `AuthScreen` (PIN entry)
- `/home` → `DashboardScreen`
- `/invoice` → `CreateInvoiceScreen`

Master data screens use `Navigator.push()` rather than named routes.

## Testing Considerations

**Database Testing**: Use `sqflite_common_ffi` (dev dependency) for testing database logic on desktop platforms during development.

**Migration Testing**: `AppDatabase.migrateForTesting()` is exposed for testing migration paths without production database access.

## Common Gotchas

1. **Unit-Product Relationship**: Products reference units by ID. Always ensure unit exists before creating/editing product.

2. **Invoice Draft Persistence**: `InvoiceController` saves draft to `SharedPreferences` automatically. Draft is restored on controller init.

3. **Date Handling**: All dates stored as ISO8601 strings in UTC. Convert to local timezone for display.

4. **Decimal Quantities**: Units have `allow_decimal` flag. Enforce integer quantities in UI when flag is 0.

5. **Invoice Number Uniqueness**: `invoice_number` has UNIQUE constraint. Controller must generate unique numbers or handle conflicts.

6. **Platform-Specific Builds**: Google Drive integration requires platform-specific setup (OAuth client IDs) in `android/` and `ios/` directories.

## Style & Code Conventions

- **Formatting**: Use `flutter format .` before committing
- **Lints**: Follow rules in `analysis_options.yaml` (uses `flutter_lints` package)
- **Private Members**: Prefix with `_` for internal controller/service state
- **Async Methods**: Always use `async`/`await`, avoid `.then()` chains

## Configuration Files

- `pubspec.yaml` - dependencies and assets
- `analysis_options.yaml` - linter rules
- `android/app/build.gradle` - Android build config and signing
- `ios/Runner/Info.plist` - iOS permissions and config

## Known Technical Debt

Based on `docs/project_completion_plan.md`:
- Backup restore flow is incomplete (upload exists, restore needs implementation)
- Test coverage is minimal (~10% complete)
- Auth security hardening needed (secure storage, biometrics)
- Some master data controllers not fully wired to database persistence
