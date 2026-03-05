import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  group('KlasBoardPostDetail model', () {
    test('parses standard board/comment payload', () {
      final detail = KlasBoardPostDetail.fromJson(<String, dynamic>{
        'board': <String, dynamic>{'boardNo': 1, 'bbsCn': '본문'},
        'boardPre': <String, dynamic>{'boardNo': 0},
        'boardNex': <String, dynamic>{'boardNo': 2},
        'comment': <Map<String, dynamic>>[
          <String, dynamic>{'cn': '댓글1'},
        ],
      });

      expect(detail.board?.raw['boardNo'], equals(1));
      expect(detail.previous?.raw['boardNo'], equals(0));
      expect(detail.next?.raw['boardNo'], equals(2));
      expect(detail.comments, hasLength(1));
      expect(detail.comments.first.raw['cn'], equals('댓글1'));
    });

    test('parses wrapped payload with alternative keys', () {
      final detail = KlasBoardPostDetail.fromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'detail': <String, dynamic>{'boardNo': 3, 'content': '본문2'},
          'previous': <String, dynamic>{'boardNo': 2},
          'next': <String, dynamic>{'boardNo': 4},
          'comments': <Map<String, dynamic>>[
            <String, dynamic>{'text': '댓글2'},
          ],
        },
      });

      expect(detail.board?.raw['boardNo'], equals(3));
      expect(detail.previous?.raw['boardNo'], equals(2));
      expect(detail.next?.raw['boardNo'], equals(4));
      expect(detail.comments, hasLength(1));
      expect(detail.comments.first.raw['text'], equals('댓글2'));
    });
  });

  group('KlasAttachedFile model', () {
    test('parses fileName key used by modern UploadFileList response', () {
      final file = KlasAttachedFile.fromJson(<String, dynamic>{
        'attachId': 'attach-1',
        'fileSn': '1',
        'fileName': 'lecture-note.pdf',
        'fileSize': 1200,
      });

      expect(file.attachId, equals('attach-1'));
      expect(file.fileSn, equals('1'));
      expect(file.fileName, equals('lecture-note.pdf'));
      expect(file.size, equals(1200));
    });
  });
}
