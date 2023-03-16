import 'dart:io';

import 'package:auth/models/update_password_body.dart';
import 'package:auth/utils/app_const.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit_core/conduit_core.dart';

import '../models/user.dart';

class AppUserController extends ResourceController {
  final ManagedContext managedContext;

  AppUserController(this.managedContext);

  @Operation.get()
  Future<Response> getProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header
  ) async {
    try {
      final id = AppUtils.getIdFromAuthHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(id)
        ?..removePropertiesFromBackingMap([
          AppConst.accessToken, 
          AppConst.refreshToken
        ]);
      return AppResponse.ok(
        body: user?.backing.contents,
        message: "Успешное получение профиля"
      );
    } catch (error) {
      return AppResponse.serverError(
        error,
        message: "Ошибка получения профиля"
      );
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() User user
  ) async {
    try {
      final id = AppUtils.getIdFromAuthHeader(header);
      final fetchedUser = await managedContext.fetchObjectWithID<User>(id);
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.username = user.username ?? fetchedUser?.username
        ..values.email = user.email ?? fetchedUser?.email;
      final updatedUser = await qUpdateUser.updateOne()
        ?..removePropertiesFromBackingMap([
            AppConst.accessToken, 
            AppConst.refreshToken
          ]);
      return AppResponse.ok(
        body: updatedUser?.backing.contents,
        message: "Успешное обновление профиля"
      );
    } catch (error) {
      return AppResponse.serverError(error);
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() UpdatePasswordBody body
  ) async {
    try {
      final id = AppUtils.getIdFromAuthHeader(header);
      final qFindUser = Query<User>(managedContext)
        ..where((user) => user.id).equalTo(id)
        ..returningProperties((user) => [user.salt, user.hashPassword]);
      final findedUser = await qFindUser.fetchOne();
      final salt = findedUser?.salt ?? "";
      final oldPasswordHash = generatePasswordHash(body.oldPassword, salt);
      if (oldPasswordHash != findedUser?.hashPassword) {
        return AppResponse.badRequest(message: "Неверный пароль");
      }
      final newHashPassword = generatePasswordHash(body.newPassword, salt);
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.hashPassword = newHashPassword;
      await qUpdateUser.updateOne();
      return AppResponse.ok(message: "Успешное обновление пароля");
    } catch (error) {
      return AppResponse.serverError(
        error, 
        message: "Успешное обновление пароля"
      );
    }
  }
}