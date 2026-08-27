abstract interface class DoctypeDataSource {
  Uri get baseUri;

  Future<Map<String, dynamic>> getDoctypeMeta(String doctype);

  Future<List<Map<String, dynamic>>> getDoctypeRows({
    required String doctype,
    required List<String> fields,
    List<List<dynamic>> filters = const [],
    List<List<dynamic>> orFilters = const [],
    String orderBy = 'name asc',
    int offset = 0,
    int limit = 20,
  });
}
