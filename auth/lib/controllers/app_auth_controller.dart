import 'dart:io';

import 'package:auth/models/app_response_model.dart';
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
        ..returningProperties((user) => [user.id, user.salt, user.hashPassword]);
      
      final findedUser = await qFindUser.fetchOne();
      if (findedUser == null) {
        throw QueryException.input("Пользователь не найден", []);
      }
      final requestHashPassword = generatePasswordHash(
        user.password ?? "", findedUser.salt ?? ""
      );
      if (requestHashPassword == findedUser.hashPassword) {
        await _updateTokens(findedUser.id ?? -1, managedContext);
        final updatedUser = await managedContext.fetchObjectWithID<User>(findedUser.id);
        return Response.ok(
          AppResponseModel(
            data: updatedUser?.backing.contents,
            message: "Успешная авторизация"
          )
        );
      } else {
        throw QueryException.input("Неверный пароль", []);
      }
    } on QueryException catch (error) {
      return Response.serverError(
        body: AppResponseModel(
          message: error.message
        )
      );
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
      return Response.ok(
        AppResponseModel(
          data: userData?.backing.contents,
          message: "Успешная регистрация"
        )
      );
    } on QueryException catch (error) {
      return Response.serverError(
        body: AppResponseModel(
          message: error.message
        )
      );
    }
  }

  @Operation.post("refresh")
  Future<Response> refreshToken(@Bind.path("refresh") String refreshToken) async {
    final User fetchedUser = User();

    //connect to DB
    //find user
    //checkToken
    //fetchUser

    return Response.ok(
      AppResponseModel(
        data: {
          "id": fetchedUser.id,
          "refreshToken": fetchedUser.refreshToken,
          "accessToken": fetchedUser.accessToken,
          }, 
        message: "Успешное обновление токенов"
      ).toJson(),
    );
  }
  
  Map<String, dynamic> _getTokens(int id) {
    // TODO remove when release
    final key = Platform.environment["SECRET_KEY"] ?? "SECRET_KEY";
    final accessClaimSet = JwtClaim(
      maxAge: Duration(hours: 1),
      otherClaims: { "id": id }
    );
    final refreshClainSet = JwtClaim(
      maxAge: Duration(hours: 1),
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
