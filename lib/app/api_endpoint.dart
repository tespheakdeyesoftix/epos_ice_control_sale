abstract final class ApiEndpoint {
  /// Authenticates a cashier and starts the Frappe session.
  ///
  /// Method: `POST`
  /// Form payload: `usr`, `pwd`, and `outlet`.
  /// Returns: the authenticated user profile, roles, employee permissions,
  /// user image, and the employee's allowed outlets. The response may be
  /// wrapped in `message`.
  static const login = 'api/method/ice_control.api.v1.auth.login';

  /// Ends the current Frappe session and clears its authentication cookies.
  ///
  /// Method: `POST`
  /// Payload: none.
  /// Returns: the standard Frappe logout response; its body is not used.
  static const logout = 'api/method/logout';

  /// Loads the products that can be sold at one outlet.
  ///
  /// Method: `POST`
  /// Form payload: `outlet`.
  /// Returns: a product list, optionally wrapped in `message`, `data`, or
  /// `products`. Each row includes product identity, category, unit, price,
  /// photo, transaction defaults, and product-level sale permissions.
  static const products = 'api/method/ice_control.api.v1.product.get_products';

  /// Reads enabled customers or drivers through the Frappe resource API.
  ///
  /// Method: `GET`
  /// Query parameters: JSON `fields`, JSON `filters`, optional JSON
  /// `or_filters`, `order_by`, `limit_start`, and `limit_page_length`.
  /// The filters select `is_customer = 1` or `is_driver = 1`.
  /// Returns: `{ "data": [Customer, ...] }`.
  static const customers = 'api/resource/Customer';

  /// Loads negotiated product prices for a selected customer.
  ///
  /// Method: `GET`
  /// Query parameters: `customer` containing the Customer document name.
  /// Returns: a list of rows containing at least `product_code`, `unit`, and
  /// `price`, optionally wrapped in `message` or `data`.
  static const customerProductPrices =
      'api/method/ice_control.api.v1.customer.get_customer_product_prices';

  /// Lists Sale documents through the Frappe resource API.
  ///
  /// Method: `GET`
  /// Query parameters: JSON `fields`, JSON `filters`, optional JSON
  /// `or_filters`, `order_by`, `limit_start`, and `limit_page_length`.
  /// Used for paginated Draft and Closed sale lists filtered by outlet.
  /// Returns: `{ "data": [Sale summary, ...] }`.
  static const sales = 'api/resource/Sale';

  /// Builds the Frappe resource URL for one complete Sale document.
  ///
  /// Method: `GET`
  /// Path parameter: the URL-encoded Sale document name.
  /// Returns: `{ "data": Sale }`, including `sale_products`.
  static String sale(String name) => '$sales/${Uri.encodeComponent(name)}';

  /// Creates or updates a Sale order.
  ///
  /// Method: `POST`
  /// Form payload: `data`, containing the JSON string
  /// `{ "doc": Sale }`. The Sale includes `sale_products` and its requested
  /// `sale_status` (`Draft` or `Closed`).
  /// Returns: the saved Sale document, optionally wrapped in `message` or
  /// `doc`.
  static const saveOrder = 'api/method/ice_control.api.v1.sale.save_order';

  /// Marks an existing Sale as deleted and records the deletion reason.
  ///
  /// Method: `POST`
  /// Form payload: `doc_name`, `deleted_note`, and `station_name` from
  /// `setting.json`.
  /// Returns: a success response; the current client does not consume its
  /// body.
  static const deleteSale = 'api/method/ice_control.api.v1.sale.delete_sale';

  /// Finds a Sale document that the cashier wants to open for editing.
  ///
  /// Method: `GET`
  /// Query parameters: scanned or typed `keyword` and the current `outlet`.
  /// Returns: one complete Sale document, optionally wrapped in `message`,
  /// `doc`, or `data`.
  static const searchBillForEdit =
      'api/method/ice_control.api.v1.sale.search_bill_for_edit';

  /// Gets the number of pending Draft orders for an outlet.
  ///
  /// Method: `GET`
  /// Query parameters: `outlet`.
  /// Returns: an integer, or an object containing `total_pending_order` or
  /// `count`, optionally wrapped in `message`.
  static const totalPendingOrder =
      'api/method/ice_control.api.v1.sale.get_total_pending_order';

  /// Gets the oldest relevant pending-order date and pending totals for an
  /// outlet so the client can warn about drafts kept for too long.
  ///
  /// Method: `GET`
  /// Query parameters: `outlet`.
  /// Returns: `{ "pending_date": DateTime, "total_pending_order": int,
  /// "pending_order_amount": number }`, optionally wrapped in `message`.
  static const maxPendingOrderDate =
      'api/method/ice_control.api.v1.sale.get_max_pending_order_date';

  /// Uses Frappe's report-view count API to count today's Closed sales.
  ///
  /// Method: `GET`
  /// Query parameters: `doctype=Sale`, JSON `filters` for outlet,
  /// `sale_status = Closed`, and today's posting-date timespan, plus
  /// `fields=[]` and `distinct=false`.
  /// Returns: the count as a number or `{ "count": number }`, optionally
  /// wrapped in `message`.
  static const reportViewCount = 'api/method/frappe.desk.reportview.get_count';

  /// Loads global/company and point-of-sale settings for the active location.
  ///
  /// Method: `GET`
  /// Query parameters: `station_name` and the current session `outlet`.
  /// Returns: the setting object, optionally wrapped in `message`, including
  /// company details, logo, stock location, currency, and payment types.
  static const setting = 'api/method/ice_control.api.v1.utils.get_setting';

  /// Lists and saves configurable receipt layouts.
  static const printTemplates = 'api/resource/POS Print Template';

  static String printTemplate(String name) =>
      '$printTemplates/${Uri.encodeComponent(name)}';
}
