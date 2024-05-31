import 'package:appium_flutter_server/src/driver.dart';
import 'package:appium_flutter_server/src/exceptions/element_not_found_exception.dart';
import 'package:appium_flutter_server/src/handler/request/request_handler.dart';
import 'package:appium_flutter_server/src/internal/element_lookup_strategy.dart';
import 'package:appium_flutter_server/src/internal/flutter_element.dart';
import 'package:appium_flutter_server/src/logger.dart';
import 'package:appium_flutter_server/src/models/api/appium_response.dart';
import 'package:appium_flutter_server/src/models/api/element.dart';
import 'package:appium_flutter_server/src/models/api/find_element.dart';
import 'package:appium_flutter_server/src/models/session.dart';
import 'package:appium_flutter_server/src/utils/element_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_plus/shelf_plus.dart';

class FindElementstHandler extends RequestHandler {
  FindElementstHandler(super.route);

  @override
  Future<AppiumResponse> handle(Request request) async {
    FindElementModel model =
        FindElementModel.fromJson(await request.body.asJson);

    final String method = model.strategy;
    final String selector = model.selector;
    final String? contextId = model.context == "" ? null : model.context;

    if (contextId == null) {
      log('"method: $method, selector: $selector');
    } else {
      log('"method: $method, selector: $selector, contextId: $contextId');
    }

    Session? session = FlutterDriver.instance.getSessionOrThrow();
    final Finder by = ElementLookupStrategy.values
        .firstWhere((val) => val.name == method)
        .toFinder(selector);
    List<Finder> matchedByList = [];
    try {
      matchedByList =
          await ElementHelper.findElements(by, contextId: contextId);
    } on ElementNotFoundException catch (e) {
      log("Got an exception while looking for multiple matches using method: $method, selector: $selector");
      log(e);
      return AppiumResponse(session!.sessionId, matchedByList);
    }

    if (matchedByList.isEmpty) {
      log("Found zero matches");
      return AppiumResponse(session!.sessionId, matchedByList);
    }

    List<ElementModel> result = [];
    for (Finder by in matchedByList) {
      FlutterElement flutterElement = await session!.elementsCache.add(by);
      result.add(ElementModel.fromElement(
          flutterElement.id, flutterElement.by.evaluate().first.hashCode));
    }

    return AppiumResponse(getSessionId(request), result);
  }
}
