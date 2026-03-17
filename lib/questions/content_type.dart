enum ContentType {
  basicSV, // was kumon7a
  descriptive, // was kumon6a
  cvcSimple, // was kumon5a
  actionSentences, // was kumon4a
  natureScene, // was kumon3a
  narrativeSentences, // was kumon2a
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
      case 'basic_sv':
        return ContentType.basicSV;
      case 'descriptive':
        return ContentType.descriptive;
      case 'cvc_simple':
        return ContentType.cvcSimple;
      case 'action':
        return ContentType.actionSentences;
      case 'nature':
        return ContentType.natureScene;
      case 'narrative':
        return ContentType.narrativeSentences;
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
      case ContentType.basicSV:
        return 'basic_sv';
      case ContentType.descriptive:
        return 'descriptive';
      case ContentType.cvcSimple:
        return 'cvc_simple';
      case ContentType.actionSentences:
        return 'action';
      case ContentType.natureScene:
        return 'nature';
      case ContentType.narrativeSentences:
        return 'narrative';
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
      case ContentType.basicSV:
        return 'Basic S-V Phrases';
      case ContentType.descriptive:
        return 'Descriptive Phrases';
      case ContentType.cvcSimple:
        return 'CVC & Simple Sentences';
      case ContentType.actionSentences:
        return 'Action Sentences';
      case ContentType.natureScene:
        return 'Nature & Scene Sentences';
      case ContentType.narrativeSentences:
        return 'Narrative Sentences';
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

  String get description {
    switch (this) {
      case ContentType.basicSV:
        return 'Short, simple actions';
      case ContentType.descriptive:
        return 'Sentences with adjectives';
      case ContentType.cvcSimple:
        return 'Focus on CVC words';
      case ContentType.actionSentences:
        return 'Dynamic verbs & adverbs';
      case ContentType.natureScene:
        return 'Nature-themed imagery';
      case ContentType.narrativeSentences:
        return 'Longer narrative flows';
      default:
        return '';
    }
  }
}
