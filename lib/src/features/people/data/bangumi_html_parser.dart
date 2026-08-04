import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

final class BangumiHtmlParser {
  const BangumiHtmlParser();

  PersonProfile parseProfile(String html, PersonSourceId id) {
    _guardSize(html);
    final rawTitle = _first(html, [
      r'<h1[^>]*>(.*?)</h1>',
      r'class="name"[^>]*>(.*?)</',
    ]);
    if (rawTitle == null || _clean(rawTitle).isEmpty) {
      throw const InvalidPayloadFailure();
    }
    final title = rawTitle;
    final summary = _first(html, [
      r'class="summary"[^>]*>(.*?)</',
      r'id="summary"[^>]*>(.*?)</',
    ]);
    final image = _first(html, [r'<img[^>]+src="([^"]+)"']);
    final aliases = _all(
      html,
      r'class="alias"[^>]*>(.*?)</',
    ).map(_clean).where((v) => v.isNotEmpty).toList(growable: false);
    final info = <String, String>{};
    for (final match in RegExp(
      r'<dt[^>]*>(.*?)</dt>\s*<dd[^>]*>(.*?)</dd>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      final key = _clean(match.group(1) ?? '');
      final value = _clean(match.group(2) ?? '');
      if (key.isNotEmpty && value.isNotEmpty) info[key] = value;
    }
    return PersonProfile(
      id: id,
      name: _clean(title),
      aliases: aliases,
      imageUrl: _uri(image),
      summary: summary == null ? null : _clean(summary),
      gender: info['性别'],
      birthDate: _date(info['生日']),
      bloodType: info['血型'],
      careers: (info['职业'] ?? '')
          .split(RegExp(r'[,、/ ]'))
          .where((v) => v.isNotEmpty)
          .toList(growable: false),
      infobox: info,
    );
  }

  static void _guardSize(String html) {
    if (html.length > 2 * 1024 * 1024) {
      throw const InvalidPayloadFailure();
    }
    if (html.trim().isEmpty) {
      throw const InvalidPayloadFailure();
    }
  }

  static String? _first(String html, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(
        pattern,
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static Iterable<String> _all(String html, String pattern) => RegExp(
    pattern,
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html).map((m) => m.group(1) ?? '');
  static String _clean(String value) => value
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static Uri? _uri(String? value) {
    final uri = value == null ? null : Uri.tryParse(value.trim());
    return uri != null && uri.hasScheme ? uri : null;
  }

  static DateTime? _date(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d{4})\D+(\d{1,2})\D+(\d{1,2})').firstMatch(value);
    if (match == null) return null;
    return DateTime.tryParse(
      '${match.group(1)}-${match.group(2)!.padLeft(2, '0')}-${match.group(3)!.padLeft(2, '0')}',
    );
  }
}

final class BangumiCommentsParser {
  const BangumiCommentsParser();

  ({List<PersonComment> comments, bool hasMore}) parse(String html) {
    if (html.length > 2 * 1024 * 1024 || html.trim().isEmpty) {
      throw const InvalidPayloadFailure();
    }
    final comments = <PersonComment>[];
    for (final match in RegExp(
      r'<article[^>]*data-comment-id="([^"]+)"[^>]*>(.*?)</article>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      final body = BangumiHtmlParser._clean(match.group(2) ?? '');
      if (body.isEmpty) continue;
      final user = RegExp(
        r'class="user"[^>]*>(.*?)</',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(match.group(2) ?? '')?.group(1);
      comments.add(
        PersonComment(
          id: match.group(1)!,
          userName: BangumiHtmlParser._clean(user ?? '匿名'),
          body: body,
        ),
      );
    }
    final hasMore = RegExp(r'(next|下一页)', caseSensitive: false).hasMatch(html);
    return (comments: comments, hasMore: hasMore);
  }
}
