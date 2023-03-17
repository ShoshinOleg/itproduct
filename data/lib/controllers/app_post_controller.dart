import 'package:data/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:data/models/author.dart';
import 'package:data/models/post.dart';


class AppPostController extends ResourceController {
  final ManagedContext managedContext;

  AppPostController(this.managedContext);

  @Operation.get()
  Future<Response> getProfile() async {
    try {
      // final id = AppUtils.getIdFromAuthHeader(header);
      // final user = await managedContext.fetchObjectWithID<User>(id)
      //   ?..removePropertiesFromBackingMap([
      //     AppConst.accessToken, 
      //     AppConst.refreshToken
      //   ]);
      return AppResponse.ok(
        // body: user?.backing.contents,
        message: "Успешное получение постов"
      );
    } catch (error) {
      return AppResponse.serverError(
        error,
        message: "Ошибка получения постов"
      );
    }
  }
}