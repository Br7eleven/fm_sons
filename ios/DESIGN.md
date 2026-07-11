Rules to capture:

No nested containers. One surface per row/card max. Never wrap a container in another container with its own background/shadow/border.
Rows are flat list items, separated by a thin 1px divider (Colors.grey.shade200 or similar) — not individual cards with shadows, unless it's a genuinely distinct section (e.g. a stats summary card).
No icon-boxes. Avoid tinted background squares behind icons unless ref app explicitly uses one (e.g. avatar initials circle is fine — that's a ref pattern; a colored square behind a ruler/person icon is not).
Minimal shadows. Reserve shadow for true elevated elements (sticky bottom bars, modals/bottom sheets) — not per-row.
Buttons: pill-shaped (StadiumBorder) for primary actions (Add Sale, Take Payment, floating actions), matching ref app's rounded pill buttons.
Sticky bottom action bars where ref app has them (e.g. Party Details: Take Payment / Add Sale) — persistent, not requiring back-navigation.
Color use: accent blue for primary/interactive, navy for branding, use existing FMSons palette constants — no new ad-hoc colors.
Consistency rule: before styling any new screen/component, check if a similar component already exists elsewhere in the app (list row, bottom sheet, button) and reuse its exact pattern — never invent a parallel style.