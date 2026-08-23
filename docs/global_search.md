# Global Sale Invoice Search

## Purpose

Global Search lets an authenticated user find closed sale invoices without leaving the current screen. It is available from the search icon beneath the company logo or with `F3`.

## Version 1 behavior

- Opening search focuses a single text input.
- Pressing `Escape` closes the dialog, including while the search input has focus.
- An empty input shows the 10 most recently modified closed sales for the active outlet, across all dates.
- A query searches invoice number, customer name, customer code, phone number, driver code, driver name, and reference number.
- The empty state is limited to 10 recent sales; keyword searches return up to 20 results. Results are displayed as cards, never as a table.
- Selecting a card closes search and opens the existing sale-invoice detail dialog.
- Each compact card includes an Edit button. It uses the existing closed-sale edit flow, including unfinished-sale, employee permission, payment-status, split-bill, and document editability checks; search stays open when editing is rejected.
- Clearing the query restores recent sales.
- The current keyword and results remain available when the dialog is closed and reopened during the same authenticated session. They are cleared when the user logs out or changes outlet.
- Loading keeps existing cards visible. Stale network responses are ignored.
- Loading, no-results, empty-recent-sales, and retryable error states are displayed in the dialog.

Draft sales remain in Pending Sales and are not included in Global Search.

## Barcode bill lookup

The authenticated application shell also listens for scanner-speed keyboard
input on every screen; no search text field needs focus. A scan is recognized
when at least three rapidly emitted characters are followed by Enter. The app
queries the Sale resource for one exact match using both the active session
outlet and the scanned document name, then opens the existing invoice detail
dialog. A slower keyboard sequence is ignored by the barcode listener.
When the Sell screen's bill-search input has focus, global barcode handling is
disabled so the scan is handled only by that search field.

## Integration

The authenticated application shell owns the `F3` shortcut and rail launcher. Both call the same guarded dialog entry point, preventing duplicate dialogs and avoiding the unfinished-sale navigation flow.

The feature controller owns query debounce, request ordering, state, and access to the sale search source. UI components live in `lib/features/global_search/widgets`.

## Future search types

Customer and Booking search should be added as separate search sources and result-card renderers behind the feature controller. The shell shortcut, rail button, and dialog launcher should remain unchanged. Add a type selector only when a second source is implemented.
