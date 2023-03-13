import 'package:auth/models/response_model.dart';
import 'package:conduit/conduit.dart';

import '../models/user.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    return Response.ok(
      ResponseModel(
        data: {
          "id": "1",
          "refreshToken": "refreshToken",
          "accessToken": "accessToken",
          }, 
        message: "signIn ok"
      ).toJson(),
    );
  }

  @Operation.put()
  Future<Response> signUp() async {
    return Response.ok(
      ResponseModel(
        data: {
          "id": "1",
          "refreshToken": "refreshToken",
          "accessToken": "accessToken",
          }, 
        message: "signUp ok"
      ).toJson(),
    );
  }

  @Operation.post("refresh")
  Future<Response> refreshToken() async {
    return Response.unauthorized(
      body: ResponseModel(error: "token in not valid").toJson()
    );
  }
}