import 'package:flutter/material.dart';
import 'persona_profile.dart';

/// ═══════════════════════════════════════════════════════════
///  PersonaAnimal — 투자 본능을 동물로 표현하는 시스템
///
///  영감: 박물관 동물 도감, 신화 속 동물 상징
///
///  매핑 차원:
///   ▸ horizon (-1 ~ +1)              : 시간 지평
///   ▸ downsideTolerance (-1 ~ +1)    : 위험 감수
///   ▸ diversificationDemand (-1 ~ +1): 분산 / 집중
///   ▸ ethicsLooseness (-1 ~ +1)      : 윤리 엄격도
///
///  결과: 8마리 동물 중 하나
///   🐯 Tiger    — 단기 + 공격
///   🦅 Eagle    — 장기 + 공격
///   🦊 Fox      — 단기 + 균형
///   🦌 Stag     — 장기 + 균형
///   🦔 Hedgehog — 단기 + 방어
///   🐢 Tortoise — 장기 + 방어
///   🐺 Wolf     — 분산 강조 (사회성)
///   🦉 Owl      — 윤리 엄격 (지혜)
/// ═══════════════════════════════════════════════════════════

class PersonaAnimal {
  final String id;
  final String name;        // 한글 이름
  final String latinName;   // 학명 풍 (Tigris Investicus)
  final String emoji;
  final String archetype;   // "전사" / "선구자" 등 한 단어
  final String tagline;     // "당신의 투자 본능은..."
  final String description; // 2-3문장 설명
  final List<String> traits;// 키워드 3개
  final Color signatureBg;  // 시그니처 배경색
  final Color signatureText;// 그 위 텍스트

  const PersonaAnimal({
    required this.id,
    required this.name,
    required this.latinName,
    required this.emoji,
    required this.archetype,
    required this.tagline,
    required this.description,
    required this.traits,
    required this.signatureBg,
    required this.signatureText,
  });

  /// PersonaProfile → PersonaAnimal 매핑
  static PersonaAnimal fromProfile(PersonaProfile p) {
    // 우선순위: 특수 차원이 강하면 그쪽 우선
    if (p.ethicsLooseness < -0.4) return _owl;
    if (p.diversificationDemand > 0.6) return _wolf;

    // 기본: horizon × downsideTolerance 4분면
    final shortTerm = p.horizon < 0;
    final aggressive = p.downsideTolerance > 0.2;
    final defensive = p.downsideTolerance < -0.2;

    if (defensive) {
      return shortTerm ? _hedgehog : _tortoise;
    }
    if (aggressive) {
      return shortTerm ? _tiger : _eagle;
    }
    // 균형
    return shortTerm ? _fox : _stag;
  }

  // ═════════════════════════════════════════════════════
  // 8마리 정의
  // ═════════════════════════════════════════════════════

  static const _tiger = PersonaAnimal(
    id: 'tiger',
    name: '호랑이',
    latinName: 'Tigris Investicus',
    emoji: '🐯',
    archetype: '전사',
    tagline: '단기 승부에 강한 본능',
    description: '시장의 흐름을 빠르게 읽고 결단합니다. 위험을 두려워하지 않으며, 짧은 시간 안에 결과를 만들어내는 데 능합니다.',
    traits: ['빠른 결단', '위험 감수', '집중 투자'],
    signatureBg: Color(0xFFB8542F),  // Terracotta
    signatureText: Color(0xFFF5E9CD),
  );

  static const _eagle = PersonaAnimal(
    id: 'eagle',
    name: '독수리',
    latinName: 'Aquila Visionaria',
    emoji: '🦅',
    archetype: '선구자',
    tagline: '높은 곳에서 멀리 보는 시야',
    description: '긴 시간 지평을 활용해 시장을 조망합니다. 단기 노이즈에 흔들리지 않고, 큰 흐름을 잡아내는 데 강점이 있습니다.',
    traits: ['장기 비전', '큰 그림', '용기'],
    signatureBg: Color(0xFF1F2E47),  // Deep Navy
    signatureText: Color(0xFFF5E9CD),
  );

  static const _fox = PersonaAnimal(
    id: 'fox',
    name: '여우',
    latinName: 'Vulpes Sagacis',
    emoji: '🦊',
    archetype: '기민함',
    tagline: '영리하고 빠른 적응력',
    description: '상황을 영리하게 판단하고 빠르게 적응합니다. 한쪽으로 치우치지 않고, 기회를 포착하는 균형 감각이 뛰어납니다.',
    traits: ['적응력', '영리함', '균형'],
    signatureBg: Color(0xFFC9A227),  // Mustard
    signatureText: Color(0xFF2D1518),
  );

  static const _stag = PersonaAnimal(
    id: 'stag',
    name: '사슴',
    latinName: 'Cervus Aequilibrium',
    emoji: '🦌',
    archetype: '균형',
    tagline: '우아한 평형의 미학',
    description: '긴 호흡으로 균형 잡힌 포트폴리오를 추구합니다. 위험과 안정 사이에서 우아한 평형을 유지하는 본능을 가졌습니다.',
    traits: ['평형', '우아함', '인내'],
    signatureBg: Color(0xFF722F37),  // Wine
    signatureText: Color(0xFFF5E9CD),
  );

  static const _hedgehog = PersonaAnimal(
    id: 'hedgehog',
    name: '고슴도치',
    latinName: 'Erinaceus Prudentius',
    emoji: '🦔',
    archetype: '신중함',
    tagline: '단단한 방어로 지키는 자산',
    description: '리스크를 미리 감지하고 단단한 방어를 우선합니다. 짧은 호흡 속에서도 잃지 않는 것을 가장 중요하게 여깁니다.',
    traits: ['방어', '신중함', '보수'],
    signatureBg: Color(0xFF6B7A5F),  // Sage Olive
    signatureText: Color(0xFFF5E9CD),
  );

  static const _tortoise = PersonaAnimal(
    id: 'tortoise',
    name: '거북이',
    latinName: 'Testudo Patientia',
    emoji: '🐢',
    archetype: '인내',
    tagline: '시간이 익혀주는 자산',
    description: '서두르지 않습니다. 안정적인 종목을 오래 보유하며, 시간이 만들어내는 복리의 힘을 신뢰합니다.',
    traits: ['장기', '안정', '복리'],
    signatureBg: Color(0xFF555A5C),  // Steel
    signatureText: Color(0xFFF5E9CD),
  );

  static const _wolf = PersonaAnimal(
    id: 'wolf',
    name: '늑대',
    latinName: 'Canis Distributus',
    emoji: '🐺',
    archetype: '무리',
    tagline: '여럿이 함께 강해지는 본능',
    description: '한 종목에 의존하지 않고, 여러 섹터에 균형 있게 분산합니다. 무리의 힘으로 리스크를 흡수합니다.',
    traits: ['분산', '협업', '안정성'],
    signatureBg: Color(0xFF4A1E24),  // Wine Deep
    signatureText: Color(0xFFF5E9CD),
  );

  static const _owl = PersonaAnimal(
    id: 'owl',
    name: '부엉이',
    latinName: 'Strix Sapientia',
    emoji: '🦉',
    archetype: '지혜',
    tagline: '윤리와 지혜의 투자자',
    description: '돈만 쫓지 않습니다. 가치 있는 산업, 윤리적인 기업을 선택해 의미 있는 자산을 만듭니다.',
    traits: ['윤리', '지혜', '책임'],
    signatureBg: Color(0xFFE8B5BE),  // Cream Pink
    signatureText: Color(0xFF2D1518),
  );

  /// 모든 동물 (탐색용)
  static const List<PersonaAnimal> all = [
    _tiger, _eagle, _fox, _stag,
    _hedgehog, _tortoise, _wolf, _owl,
  ];
}