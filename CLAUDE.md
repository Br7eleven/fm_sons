# CLAUDE.md

FM Sons - Flutter billing app with SQLite, PDF invoices, Google Drive backup.

## State Management (Provider)
- `ThemeController`, `InvoiceController`, `UnitController`, `ProductController`, `CustomerController`, `NoteController` in `main.dart`
- `ProductController` depends on `UnitController`
- `ThemeController` manages app-wide theme (Light/Dark/System)

## Database
- **Version**: 3 (schema in `AppDatabase.schemaVersion`)
- **Tables**: customers, units, products, contracts, invoices, invoice_items, notes
- **Migration**: Increment version → add `_migrateVxToVy()` block → preserve legacy data with fallbacks
- **Access**: Use DAOs (`lib/data/local/dao/`), never raw SQL in UI

## Structure
```
lib/data/local/   # SQLite tables, DAOs, models
lib/view/         # UI screens, widgets, controllers
  ├── invoice/    # Invoice creation, preview, PDF templates (tax_1, tax_3, modern, orange, blue)
  ├── masters/    # Customer, product, unit CRUD
  ├── notes/      # Notes list, detail screens
  ├── settings/   # Theme controller, settings screens
  └── shared/     # Shared widgets (app_drawer, bottom_nav)
```

## Critical Patterns
- **Controllers**: Check `_initialized` before accessing data
- **Transactions**: Use `db.transaction()` for multi-step ops
- **Null safety**: Legacy data may have null FKs (use fallback labels)
- **PDF**: High-res capture with `pixelRatio: 6.0` for 300 DPI print quality
- **Navigation**: Use `Navigator.push()` for masters/notes
- **Drawer**: Use `AppDrawer(currentRoute: 'route_name')` on main screens for consistent navigation

## Key Features
- Invoice templates with A4 layout (`FittedBox` in base, AspectRatio removed from preview)
- PDF generation via screen capture (blur fixed with 6.0 pixel ratio)
- Notes module with search, share (`share_plus`), CRUD
- Dashboard quick actions for invoices, clients, notes
- Navigation drawer (sidebar) with FM Sons branding, accessible from main screens
- Theme switching (Light/Dark/System) with persistent preference in SharedPreferences

## Code Style
- Format: `dart format .`
- Async: Use `async`/`await` (no `.then()`)
- Private: Prefix `_` for internal state

## Navigation Drawer
- **Location**: `lib/view/shared/app_drawer.dart`
- **Usage**: Add `drawer: AppDrawer(currentRoute: 'route_name')` to main screens
- **Design**: Gradient header with FM Sons branding, blue primary color (`0xFF1E3A8A`)
- **Items**: FM Sons Profile (coming soon), Clients, Notes, Settings
- **Active state**: Highlighted with primary color border and background tint
- **Theme Switcher**: Bottom of drawer, three options (Light/Dark/System)
- **Kept bottom nav**: Coexists with bottom navigation for hybrid navigation pattern

## Theme Management
- **Controller**: `ThemeController` in `lib/view/settings/theme_controller.dart`
- **Modes**: Light, Dark, System (follows device setting)
- **Persistence**: Saved in SharedPreferences, auto-loaded on app start
- **Colors**: Same brand blue (`0xFF1E3A8A`) in both themes
- **Switcher**: In app drawer, three-button toggle with icons