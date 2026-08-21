# Global Sale Invoice Search

## Purpose

Global Search lets an authenticated user find closed sale invoices without leaving the current screen. It is available from the search icon beneath the company logo or with `F3`.

## Version 1 behavior

- Opening search focuses a single text input.
- An empty input shows the 10 most recently modified closed sales for the active outlet, across all dates.
- A query searches invoice number, customer name, customer code, and phone number.
- Results are limited to 10 and displayed as cards, never as a table.
- Selecting a card closes search and opens the existing sale-invoice detail dialog.
- Clearing the query restores recent sales.
- Queries and results are not persisted after the dialog closes.
- Loading keeps existing cards visible. Stale network responses are ignored.
- Loading, no-results, empty-recent-sales, and retryable error states are displayed in the dialog.

Draft sales remain in Pending Sales and are not included in Global Search.

## Integration

The authenticated application shell owns the `F3` shortcut and rail launcher. Both call the same guarded dialog entry point, preventing duplicate dialogs and avoiding the unfinished-sale navigation flow.

The feature controller owns query debounce, request ordering, state, and access to the sale search source. UI components live in `lib/features/global_search/widgets`.

## Future search types

Customer and Booking search should be added as separate search sources and result-card renderers behind the feature controller. The shell shortcut, rail button, and dialog launcher should remain unchanged. Add a type selector only when a second source is implemented.
