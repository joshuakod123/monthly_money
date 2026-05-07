import 'package:flutter/material.dart';
import 'persona_profile.dart';

/// ═══════════════════════════════════════════════════════════
///  PersonaAnimal v2 — Image 3 영감 ("ANIMAL PLANET" 스타일)
///
///  ▸ 강한 단일 컬러 풀스크린 (red/green/gray 등)
///  ▸ 거대한 픽셀풍 sans 타이포가 그림 위로 뚫고 지나감
///  ▸ 동물은 흑백 디테일 일러스트 (CustomPainter로 그림)
///  ▸ 인덱스 번호 (4/10) + Discover 세로 텍스트
/// ═══════════════════════════════════════════════════════════

class PersonaAnimal {
  final String id;
  final String name;        // 한글 이름
  final String displayName; // 영문 대문자 (TIGER, EAGLE...)
  final String latinName;   // Tigris Investicus
  final String archetype;
  final String tagline;
  final String description;
  final List<String> traits;

  /// Image 3 스타일 컬러 (강하고 채도 높음)
  final Color signatureBg;
  final Color signatureText;   // 그 위 메인 텍스트
  final Color illustrationInk; // 일러스트 잉크 색

  /// 인덱스 (1/8 표시용)
  final int index;
  /// 일러스트 ID (CustomPainter에서 그림 분기용)
  final String illustrationId;

  const PersonaAnimal({
    required this.id,
    required this.name,
    required this.displayName,
    required this.latinName,
    required this.archetype,
    required this.tagline,
    required this.description,
    required this.traits,
    required this.signatureBg,
    required this.signatureText,
    required this.illustrationInk,
    required this.index,
    required this.illustrationId,
  });

  static PersonaAnimal fromProfile(PersonaProfile p) {
    if (p.ethicsLooseness < -0.4) return _owl;
    if (p.diversificationDemand > 0.6) return _wolf;

    final shortTerm = p.horizon < 0;
    final aggressive = p.downsideTolerance > 0.2;
    final defensive = p.downsideTolerance < -0.2;

    if (defensive) return shortTerm ? _hedgehog : _tortoise;
    if (aggressive) return shortTerm ? _tiger : _eagle;
    return shortTerm ? _fox : _stag;
  }

  // ═════════════════════════════════════════════════════
  //  8마리 — Image 3 스타일 강한 색상으로 재정의
  // ═════════════════════════════════════════════════════

  static const _tiger = PersonaAnimal(
    id: 'tiger',
    name: '호랑이',
    displayName: 'TIGER',
    latinName: 'Tigris Investicus',
    archetype: '전사',
    tagline: '단기 승부에 강한 본능',
    description:
    '시장 흐름을 빠르게 읽고 결단해요. 위험을 두려워하지 않고, 짧은 시간 안에 결과를 만들어내는 데 능해요',
    traits: ['빠른 결단', '위험 감수', '집중'],
    signatureBg: Color(0xFFB8B8B8),    // 회색 (Image 3 좌)
    signatureText: Color(0xFF1A1A1A),
    illustrationInk: Color(0xFF1A1A1A),
    index: 1,
    illustrationId: 'tiger',
  );

  static const _eagle = PersonaAnimal(
    id: 'eagle',
    name: '독수리',
    displayName: 'EAGLE',
    latinName: 'Aquila Visionaria',
    archetype: '선구자',
    tagline: '높은 곳에서 멀리 보는 시야',
    description:
    '긴 시간 지평을 활용해 시장을 조망해요. 단기 노이즈에 흔들리지 않고, 큰 흐름을 잡는 데 강점이 있어요',
    traits: ['장기 비전', '큰 그림', '용기'],
    signatureBg: Color(0xFF1F2E47),    // 딥 네이비
    signatureText: Color(0xFFF5E9CD),
    illustrationInk: Color(0xFFF5E9CD),
    index: 2,
    illustrationId: 'eagle',
  );

  static const _fox = PersonaAnimal(
    id: 'fox',
    name: '여우',
    displayName: 'FOX',
    latinName: 'Vulpes Sagacis',
    archetype: '기민함',
    tagline: '영리하고 빠른 적응력',
    description:
    '상황을 영리하게 판단하고 빠르게 적응해요. 한쪽으로 치우치지 않고 기회를 포착하는 균형 감각이 있어요',
    traits: ['적응력', '영리함', '균형'],
    signatureBg: Color(0xFFE85D2A),    // 강한 오렌지
    signatureText: Color(0xFF1A1A1A),
    illustrationInk: Color(0xFF1A1A1A),
    index: 3,
    illustrationId: 'fox',
  );

  static const _stag = PersonaAnimal(
    id: 'stag',
    name: '사슴',
    displayName: 'STAG',
    latinName: 'Cervus Aequilibrium',
    archetype: '균형',
    tagline: '우아한 평형의 미학',
    description:
    '긴 호흡으로 균형 잡힌 포트폴리오를 추구해요. 위험과 안정 사이에서 우아한 평형을 유지해요',
    traits: ['평형', '우아함', '인내'],
    signatureBg: Color(0xFFD9C8A0),    // 딥 베이지
    signatureText: Color(0xFF2D1518),
    illustrationInk: Color(0xFF2D1518),
    index: 4,
    illustrationId: 'stag',
  );

  static const _hedgehog = PersonaAnimal(
    id: 'hedgehog',
    name: '고슴도치',
    displayName: 'HEDGEHOG',
    latinName: 'Erinaceus Prudentius',
    archetype: '신중',
    tagline: '단단한 방어로 지키는 자산',
    description:
    '리스크를 미리 감지하고 단단한 방어를 우선해요. 짧은 호흡 속에서도 잃지 않는 것을 가장 중요하게 여겨요',
    traits: ['방어', '신중', '보수'],
    signatureBg: Color(0xFF7A6F4F),    // 머스타드 올리브
    signatureText: Color(0xFFF5E9CD),
    illustrationInk: Color(0xFFF5E9CD),
    index: 5,
    illustrationId: 'hedgehog',
  );

  static const _tortoise = PersonaAnimal(
    id: 'tortoise',
    name: '거북이',
    displayName: 'TORTOISE',
    latinName: 'Testudo Patientia',
    archetype: '인내',
    tagline: '시간이 익혀주는 자산',
    description:
    '서두르지 않아요. 안정적인 종목을 오래 보유하며 시간이 만들어내는 복리의 힘을 신뢰해요',
    traits: ['장기', '안정', '복리'],
    signatureBg: Color(0xFF2A8A6C),    // 강한 그린 (Image 3 우)
    signatureText: Color(0xFFF5E9CD),
    illustrationInk: Color(0xFFF5E9CD),
    index: 6,
    illustrationId: 'tortoise',
  );

  static const _wolf = PersonaAnimal(
    id: 'wolf',
    name: '늑대',
    displayName: 'WOLF',
    latinName: 'Canis Distributus',
    archetype: '무리',
    tagline: '여럿이 함께 강해지는 본능',
    description:
    '한 종목에 의존하지 않고 여러 섹터에 균형 있게 분산해요. 무리의 힘으로 리스크를 흡수해요',
    traits: ['분산', '협업', '안정'],
    signatureBg: Color(0xFF4A1E24),    // 와인 딥
    signatureText: Color(0xFFF5E9CD),
    illustrationInk: Color(0xFFF5E9CD),
    index: 7,
    illustrationId: 'wolf',
  );

  static const _owl = PersonaAnimal(
    id: 'owl',
    name: '부엉이',
    displayName: 'OWL',
    latinName: 'Strix Sapientia',
    archetype: '지혜',
    tagline: '윤리와 지혜의 투자자',
    description:
    '돈만 쫓지 않아요. 가치 있는 산업, 윤리적인 기업을 선택해 의미 있는 자산을 만들어요',
    traits: ['윤리', '지혜', '책임'],
    signatureBg: Color(0xFFE8B5BE),    // 크림 핑크
    signatureText: Color(0xFF2D1518),
    illustrationInk: Color(0xFF2D1518),
    index: 8,
    illustrationId: 'owl',
  );

  static const List<PersonaAnimal> all = [
    _tiger, _eagle, _fox, _stag,
    _hedgehog, _tortoise, _wolf, _owl,
  ];
}
