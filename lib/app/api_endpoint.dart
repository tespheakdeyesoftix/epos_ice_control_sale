abstract final class ApiEndpoint {
  static const login = 'api/method/ice_control.api.v1.auth.login';
  static const logout = 'api/method/logout';
  static const products = 'api/method/ice_control.api.v1.product.get_products';
  static const customers = 'api/resource/Customer';
  static const customerProductPrices =
      'api/method/ice_control.api.v1.customer.get_customer_product_prices';
  static const sales = 'api/resource/Sale';
  static String sale(String name) => '$sales/${Uri.encodeComponent(name)}';
  static const saveOrder = 'api/method/ice_control.api.v1.sale.save_order';
  static const totalPendingOrder =
      'api/method/ice_control.api.v1.sale.get_total_pending_order';
  static const reportViewCount = 'api/method/frappe.desk.reportview.get_count';
  static const setting = 'api/method/ice_control.api.v1.utils.get_setting';
}
