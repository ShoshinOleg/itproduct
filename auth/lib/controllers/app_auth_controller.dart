import 'package:auth/models/app_response_model.dart';
import 'package:auth/utils/app_env.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../models/user.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.username == null) {
      return Response.badRequest(
        body: AppResponseModel(message: "Поля password username обязательны")
      );
    }

    try {
      final qFindUser = Query<User>(managedContext)
        ..where((user) => user.username).equalTo(user.username)
        ..returningProperties((user) => 
          [user.id, user.salt, user.hashPassword]
        );
      
      final findedUser = await qFindUser.fetchOne();
      if (findedUser == null) {
        throw QueryException.input("Пользователь не найден", []);
      }
      final requestHashPassword = generatePasswordHash(
        user.password ?? "", findedUser.salt ?? ""
      );
      if (requestHashPassword == findedUser.hashPassword) {
        await _updateTokens(findedUser.id ?? -1, managedContext);
        final updatedUser = await managedContext
          .fetchObjectWithID<User>(findedUser.id);
        return AppResponse.ok(
            body: updatedUser?.backing.contents,
            message: "Успешная авторизация"
        );
      } else {
        throw QueryException.input("Неверный пароль", []);
      }
    } catch (error) {
      return AppResponse.serverError(error, message: "Ошибка авторизации");
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.username == null || user.email == null) {
      return Response.badRequest(
        body: AppResponseModel(message: "Поля password username email обязательны")
      );
    }

    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password ?? "", salt);

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;
        final createdUser = await qCreateUser.insert();
        id = createdUser.asMap()["id"];
        await _updateTokens(id, transaction);
      });
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return AppResponse.ok(
        body: userData?.backing.contents,
        message: "Успешная регистрация"
      );
    } catch (error) {
      return AppResponse.serverError(error, message: "Ошибка регистрации");
    }
  }

  @Operation.post("refresh")
  Future<Response> refreshToken(
    @Bind.path("refresh") String refreshToken
  ) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);
      if (user?.refreshToken != refreshToken) {
        return Response.unauthorized(
          body: AppResponseModel(message: "Token is not valid")
        );
      } else {
        await _updateTokens(id, managedContext);
        final updatedUser = await managedContext.fetchObjectWithID<User>(id);
        return AppResponse.ok(
          body: updatedUser?.backing.contents,
          message: "Успешное обновление токенов"
        );
      }
    } catch (error) {
      return AppResponse.serverError(error, message: "Ошибка обновления токенов");
    }
  }
  
  Map<String, dynamic> _getTokens(int id) {
    final key = AppEnv.secretKey;
    final accessClaimSet = JwtClaim(
      maxAge: Duration(hours: 1),
      otherClaims: { "id": id }
    );
    final refreshClainSet = JwtClaim(
      otherClaims: { "id": id }
    );
    final tokens = <String, dynamic>{};
    tokens["access"] = issueJwtHS256(accessClaimSet, key);
    tokens["refresh"] = issueJwtHS256(refreshClainSet, key);
    return tokens;
  }

  Future<void> _updateTokens(int id, ManagedContext transaction) async {
      final Map<String, dynamic> tokens = _getTokens(id);
      final qUpdateTokens = Query<User>(transaction)
        ..where((user) => user.id).equalTo(id)
        ..values.accessToken = tokens["access"]
        ..values.refreshToken = tokens["refresh"];
      await qUpdateTokens.updateOne();
  }
}
