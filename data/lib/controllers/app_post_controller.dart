import 'dart:io';

import 'package:data/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:data/models/author.dart';
import 'package:data/models/post.dart';

import '../utils/app_utils.dart';


class AppPostController extends ResourceController {
  final ManagedContext managedContext;

  AppPostController(this.managedContext);

  @Operation.get("id")
  Future<Response> getPost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id
  ) async {
    try {
      final currentAuthorId = AppUtils.getIdFromAuthHeader(header);
      final qGetPost = Query<Post>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..where((x) => x.author?.id).equalTo(currentAuthorId)
        ..returningProperties((x) => [x.id, x.content, x.name]);
      final post = await qGetPost.fetchOne();
      if (post == null) {
        return AppResponse.ok(message: "Пост не найден");
      }
      return AppResponse.ok(
        body: post.backing.contents,
        message: "Успешное получение поста"
      );
    } catch (error) {
      return AppResponse.serverError(
        error,
        message: "Ошибка получения поста"
      );
    }
  }

  @Operation.post()
  Future<Response> createPost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() Post post
  ) async {
    try {
      if (post.content == null || 
        post.content?.isEmpty == true ||
        post.name == null ||
        post.name?.isEmpty == true) {
          return AppResponse.badRequest(message: "Поля name и content обязательны");
      }
      final id = AppUtils.getIdFromAuthHeader(header);
      final author = await managedContext.fetchObjectWithID<Author>(id);
      if (author == null) {
        final qCreateAuthor = Query<Author>(managedContext)..values.id = id;
        await qCreateAuthor.insert();
      }

      final contentLength = post.content?.length ?? 0;
      final qCreatePost = Query<Post>(managedContext)
        ..values.author?.id = id
        ..values.name = post.name
        ..values.preContent = post.content?.substring(
          0, 
          contentLength <= 20 ? contentLength : 20
        )
        ..values.content = post.content;
      await qCreatePost.insert();
      return AppResponse.ok(
        // body: createdPost.backing.contents,
        message: "Успешное создания поста"
      );
    } catch (error) {
      return AppResponse.serverError(
        error,
        message: "Ошибка создания поста"
      );
    }
  }

  @Operation.delete("id")
  Future<Response> deletePost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id
  ) async {
    try {
      final currentAuthorId = AppUtils.getIdFromAuthHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.ok(message: "Пост не найден");
      }
      if (post.author?.id != currentAuthorId) {
        return AppResponse.ok(message: "Нет доступа к посту");
      }
      post.backing.removeProperty("author");

      final qDeletePost = Query<Post>(managedContext)
        ..where((x) => x.id).equalTo(id);
      await qDeletePost.delete();

      return AppResponse.ok(
        body: post.backing.contents,
        message: "Успешное удаление поста"
      );
    } catch (error) {
      return AppResponse.serverError(
        error,
        message: "Ошибка удаления поста"
      );
    }
  }

  @Operation.get()
  Future<Response> getPosts(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      final currentAuthorId = AppUtils.getIdFromAuthHeader(header);
      final qGetPosts = Query<Post>(managedContext)
        ..where((x) => x.author?.id).equalTo(currentAuthorId);
      final List<Post> posts = await qGetPosts.fetch();
      return Response.ok(posts);
    } catch (error) {
      return AppResponse.serverError(
        error,
        message: "Ошибка получения постов"
      );
    }
  }
}