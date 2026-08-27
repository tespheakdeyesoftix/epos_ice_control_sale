# Project terminology

- Translate **Quantity** into Khmer as **ចំនួន**.
- Do not use **បរិមាណ** as the Khmer translation for **Quantity**.

- Translate **Outlet** into Khmer as **កន្លែងលក់**.
- Do not use **សាខា** as the Khmer translation for **Outlet**.

# UI notifications

- Use GetX toast notifications (`Get.rawSnackbar`) for all transient toast messages.
- Do not use `ScaffoldMessenger` or Flutter `SnackBar` for toast messages.

# Khmer typography

- Use `AppTheme.fontFamily` (`NotoSansKhmer`) for Khmer UI text, including text styles defined directly on buttons and dialogs.
- Use only the bundled Khmer font weights `FontWeight.w400` and `FontWeight.w700`. Do not use synthetic weights such as 800 or 900 for Khmer text.
