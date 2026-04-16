import 'package:cloud_functions/cloud_functions.dart';

class XpStoreService {
  XpStoreService(this._functions);

  final FirebaseFunctions _functions;

  Future<void> purchaseItem(String itemId) async {
    final callable = _functions.httpsCallable('xpStorePurchase');
    await callable.call({'itemId': itemId});
  }
}
