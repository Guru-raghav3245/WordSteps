enum ContentType {
  kumon7a,
  kumon6a,
  kumon5a,
  kumon4a,
  kumon3a,
  kumon2a,
  wordLength3,
  wordLength4,
  wordLength5,
  wordLength6,
  wordLength7,
  wordLength8,
  wordLength9,
  wordLength10,
  wordLength11,
  wordLength12,
  wordLength13,
  wordLength14;

  static ContentType fromName(String name) {
    switch (name) {
      case '7a':
        return ContentType.kumon7a;
      case '6a':
        return ContentType.kumon6a;
      case '5a':
        return ContentType.kumon5a;
      case '4a':
        return ContentType.kumon4a;
      case '3a':
        return ContentType.kumon3a;
      case '2a':
        return ContentType.kumon2a;
      case '3':
        return ContentType.wordLength3;
      case '4':
        return ContentType.wordLength4;
      case '5':
        return ContentType.wordLength5;
      case '6':
        return ContentType.wordLength6;
      case '7':
        return ContentType.wordLength7;
      case '8':
        return ContentType.wordLength8;
      case '9':
        return ContentType.wordLength9;
      case '10':
        return ContentType.wordLength10;
      case '11':
        return ContentType.wordLength11;
      case '12':
        return ContentType.wordLength12;
      case '13':
        return ContentType.wordLength13;
      case '14':
        return ContentType.wordLength14;
      default:
        throw Exception('Invalid content type name: $name');
    }
  }
}

extension ContentTypeExtension on ContentType {
  String get name {
    switch (this) {
      case ContentType.kumon7a:
        return '7a';
      case ContentType.kumon6a:
        return '6a';
      case ContentType.kumon5a:
        return '5a';
      case ContentType.kumon4a:
        return '4a';
      case ContentType.kumon3a:
        return '3a';
      case ContentType.kumon2a:
        return '2a';
      case ContentType.wordLength3:
        return '3';
      case ContentType.wordLength4:
        return '4';
      case ContentType.wordLength5:
        return '5';
      case ContentType.wordLength6:
        return '6';
      case ContentType.wordLength7:
        return '7';
      case ContentType.wordLength8:
        return '8';
      case ContentType.wordLength9:
        return '9';
      case ContentType.wordLength10:
        return '10';
      case ContentType.wordLength11:
        return '11';
      case ContentType.wordLength12:
        return '12';
      case ContentType.wordLength13:
        return '13';
      case ContentType.wordLength14:
        return '14';
    }
  }

  String get displayName {
    switch (this) {
      case ContentType.kumon7a:
        return '7A Sentences';
      case ContentType.kumon6a:
        return '6A Sentences';
      case ContentType.kumon5a:
        return '5A Sentences';
      case ContentType.kumon4a:
        return '4A Sentences';
      case ContentType.kumon3a:
        return '3A Sentences';
      case ContentType.kumon2a:
        return '2A Sentences';
      case ContentType.wordLength3:
        return '3 Letter Words';
      case ContentType.wordLength4:
        return '4 Letter Words';
      case ContentType.wordLength5:
        return '5 Letter Words';
      case ContentType.wordLength6:
        return '6 Letter Words';
      case ContentType.wordLength7:
        return '7 Letter Words';
      case ContentType.wordLength8:
        return '8 Letter Words';
      case ContentType.wordLength9:
        return '9 Letter Words';
      case ContentType.wordLength10:
        return '10 Letter Words';
      case ContentType.wordLength11:
        return '11 Letter Words';
      case ContentType.wordLength12:
        return '12 Letter Words';
      case ContentType.wordLength13:
        return '13 Letter Words';
      case ContentType.wordLength14:
        return '14 Letter Words';
    }
  }
}