import 'dart:math' as math;

/// ═══════════════════════════════════════════════════════════
///  Persona Profile — 사용자의 8차원 벡터
/// ═══════════════════════════════════════════════════════════
///
///  각 차원은 -1.0 ~ +1.0 범위로 정규화되어,
///  종목별 Stock Vector와 매칭에 사용됨.
///
///  같은 "200만원 + 금융" 사용자라도 이 8차원 답이 다르면
///  완전히 다른 추천 결과가 나오도록 설계.
/// ═══════════════════════════════════════════════════════════

class PersonaProfile {
  /// 시간 지평: -1.0 (3년 이내) ~ +1.0 (15년+)
  final double horizon;

  /// 현금흐름 패턴: -1.0 (균등 월배당 선호) ~ +1.0 (큰 분기·연배당 OK)
  final double cashflowPreference;

  /// 하방 방어: -1.0 (변동성 절대 못참음) ~ +1.0 (기회로 봄)
  final double downsideTolerance;

  /// 세금 민감도: -1.0 (분리과세 ETF만) ~ +1.0 (세금 신경 안씀)
  final double taxSensitivity;

  /// 유동성 요구: -1.0 (언제든 팔 수 있어야) ~ +1.0 (장기 묶어둠 OK)
  final double liquidityNeed;

  /// ESG 윤리: -1.0 (담배·도박 절대 X) ~ +1.0 (수익이면 다 OK)
  final double ethicsLooseness;

  /// 다각화 강도: -1.0 (한 섹터 몰빵 OK) ~ +1.0 (반드시 분산)
  final double diversificationDemand;

  /// 인플레이션 헷지: -1.0 (현금가치 신경 안씀) ~ +1.0 (실물자산 선호)
  final double inflationHedge;

  /// 기본 정보 (질문에서 직접 받음)
  final int monthlyTarget;
  final int budget;
  final List<String> preferredSectors; // 'finance' / 'reit' 등
  final List<String> excludedSectors;

  const PersonaProfile({
    required this.horizon,
    required this.cashflowPreference,
    required this.downsideTolerance,
    required this.taxSensitivity,
    required this.liquidityNeed,
    required this.ethicsLooseness,
    required this.diversificationDemand,
    required this.inflationHedge,
    required this.monthlyTarget,
    required this.budget,
    required this.preferredSectors,
    required this.excludedSectors,
  });

  /// 결정론적 시드 — 같은 답이면 같은 결과 (신뢰성)
  /// 단, 사용자별 미세 차이를 위해 답변 벡터 자체에서 시드 생성
  int get deterministicSeed {
    final v = [
      horizon,
      cashflowPreference,
      downsideTolerance,
      taxSensitivity,
      liquidityNeed,
      ethicsLooseness,
      diversificationDemand,
      inflationHedge,
      monthlyTarget / 1000000,
      budget / 100000000,
    ];
    int seed = 0;
    for (var i = 0; i < v.length; i++) {
      seed ^= ((v[i] * 1000).round() & 0xFFFF) << (i % 4);
    }
    return seed.abs();
  }

  /// 8차원 벡터 표현 (코사인 유사도 계산용)
  List<double> get vector => [
    horizon,
    cashflowPreference,
    downsideTolerance,
    taxSensitivity,
    liquidityNeed,
    ethicsLooseness,
    diversificationDemand,
    inflationHedge,
  ];

  /// 인간 친화적 요약 ("당신은 ___형 투자자입니다")
  String summarize() {
    final traits = <String>[];
    if (horizon < -0.3) traits.add('단기형');
    else if (horizon > 0.3) traits.add('장기형');
    if (downsideTolerance < -0.3) traits.add('방어형');
    else if (downsideTolerance > 0.3) traits.add('공격형');
    if (cashflowPreference < -0.3) traits.add('월급형');
    if (diversificationDemand > 0.5) traits.add('분산형');
    if (inflationHedge > 0.4) traits.add('실물자산형');
    if (ethicsLooseness < -0.3) traits.add('윤리중시');
    if (traits.isEmpty) traits.add('균형형');
    return traits.join(' · ');
  }
}

/// ═══════════════════════════════════════════════════════════
///  스무고개 질문 정의 (8문항)
///
///  각 답변은 1-2개의 차원에 가중치로 영향을 줌.
///  이 매트릭스가 알고리즘의 "성격"을 결정.
/// ═══════════════════════════════════════════════════════════
class QuizQuestion {
  final String id;
  final String question;
  final String? subtitle;
  final List<QuizOption> options;
  final QuestionType type;

  const QuizQuestion({
    required this.id,
    required this.question,
    this.subtitle,
    required this.options,
    this.type = QuestionType.singleChoice,
  });
}

enum QuestionType { singleChoice, multiChoice, slider }

class QuizOption {
  final String label;
  final String? description;
  final String emoji;
  /// 차원별 영향도 — 예: {'horizon': -0.8, 'liquidityNeed': 0.5}
  final Map<String, double> impact;

  const QuizOption({
    required this.label,
    this.description,
    required this.emoji,
    required this.impact,
  });
}

/// 스무고개 질문 데이터셋
class QuizBank {
  static const List<QuizQuestion> questions = [
    QuizQuestion(
      id: 'q1_horizon',
      question: '월 배당 목표를 언제까지 달성하고 싶으세요?',
      subtitle: '시간이 많을수록 성장주를 섞어 추천해드려요',
      options: [
        QuizOption(
          label: '3년 안에',
          description: '빠르게 결과를 보고 싶어요',
          emoji: '🏃',
          impact: {'horizon': -0.9, 'cashflowPreference': -0.3},
        ),
        QuizOption(
          label: '5~7년',
          description: '적당한 속도로',
          emoji: '🚶',
          impact: {'horizon': -0.2},
        ),
        QuizOption(
          label: '10년 이상',
          description: '천천히 복리로',
          emoji: '🌱',
          impact: {'horizon': 0.6, 'downsideTolerance': 0.3},
        ),
        QuizOption(
          label: '15년 이상 / 은퇴 자금',
          description: '시간이 충분해요',
          emoji: '🏔️',
          impact: {'horizon': 0.95, 'inflationHedge': 0.5},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q2_cashflow',
      question: '배당금이 어떻게 들어오면 좋을까요?',
      subtitle: '월급처럼 vs 보너스처럼',
      options: [
        QuizOption(
          label: '매달 균등하게',
          description: '월급처럼 매달 비슷한 금액',
          emoji: '📅',
          impact: {'cashflowPreference': -0.9},
        ),
        QuizOption(
          label: '분기마다',
          description: '3개월에 한 번씩 큼직하게',
          emoji: '📆',
          impact: {'cashflowPreference': -0.2},
        ),
        QuizOption(
          label: '연 1~2회 큰 금액',
          description: '보너스처럼 한 번에',
          emoji: '🎁',
          impact: {'cashflowPreference': 0.7},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q3_downside',
      question: '내 주식이 한 달 만에 -30% 떨어졌어요. 어떻게 할까요?',
      subtitle: '솔직하게 답해주세요 — 정답은 없어요',
      options: [
        QuizOption(
          label: '바로 다 팔아요',
          description: '잠 못 자느니 손절',
          emoji: '😱',
          impact: {'downsideTolerance': -0.95, 'liquidityNeed': -0.6},
        ),
        QuizOption(
          label: '불안하지만 버텨요',
          description: '회복을 기대하면서',
          emoji: '😟',
          impact: {'downsideTolerance': -0.2},
        ),
        QuizOption(
          label: '오히려 더 사요',
          description: '싸게 살 기회',
          emoji: '😎',
          impact: {'downsideTolerance': 0.7, 'horizon': 0.3},
        ),
        QuizOption(
          label: '뉴스 안 봐요',
          description: '신경 끄고 묻어둠',
          emoji: '🙈',
          impact: {'downsideTolerance': 0.5, 'liquidityNeed': 0.6},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q4_tax',
      question: '예상 연간 금융소득이 어느 정도예요?',
      subtitle: '연 2,000만원 초과 시 종합과세 대상이에요',
      options: [
        QuizOption(
          label: '500만원 이하',
          emoji: '🪙',
          impact: {'taxSensitivity': 0.6},
        ),
        QuizOption(
          label: '500~2,000만원',
          emoji: '💰',
          impact: {'taxSensitivity': 0.0},
        ),
        QuizOption(
          label: '2,000만원 초과',
          description: '종합과세 회피하고 싶어요',
          emoji: '💸',
          impact: {'taxSensitivity': -0.9},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q5_liquidity',
      question: '갑자기 큰 돈이 필요할 가능성은?',
      subtitle: '결혼·이사·창업 등',
      options: [
        QuizOption(
          label: '1~2년 안에 가능성 있음',
          emoji: '🚨',
          impact: {'liquidityNeed': -0.85, 'downsideTolerance': -0.3},
        ),
        QuizOption(
          label: '5년 정도는 안 건드릴 수 있어요',
          emoji: '🔒',
          impact: {'liquidityNeed': 0.3},
        ),
        QuizOption(
          label: '아예 묻어둘 자금이에요',
          emoji: '🗿',
          impact: {'liquidityNeed': 0.9, 'horizon': 0.4},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q6_ethics',
      question: '어떤 산업은 피하고 싶으세요?',
      subtitle: '복수 선택 가능 — 제외할 섹터를 알려주세요',
      type: QuestionType.multiChoice,
      options: [
        QuizOption(
          label: '담배 / 주류',
          emoji: '🚭',
          impact: {'ethicsLooseness': -0.4, '_exclude_consumer_sin': 1.0},
        ),
        QuizOption(
          label: '카지노 / 도박',
          emoji: '🎰',
          impact: {'ethicsLooseness': -0.4, '_exclude_gambling': 1.0},
        ),
        QuizOption(
          label: '방산 / 무기',
          emoji: '🔫',
          impact: {'ethicsLooseness': -0.3, '_exclude_defense': 1.0},
        ),
        QuizOption(
          label: '화석연료',
          emoji: '🛢️',
          impact: {'ethicsLooseness': -0.3, '_exclude_fossil': 1.0},
        ),
        QuizOption(
          label: '없음 / 수익이면 OK',
          emoji: '💼',
          impact: {'ethicsLooseness': 0.6},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q7_diversity',
      question: '한 산업에 집중 vs 여러 산업 분산?',
      subtitle: '집중하면 수익률 ↑ 변동성 ↑',
      options: [
        QuizOption(
          label: '확신 있는 한두 섹터에 집중',
          emoji: '🎯',
          impact: {'diversificationDemand': -0.7, 'downsideTolerance': 0.3},
        ),
        QuizOption(
          label: '3~4개 섹터에 골고루',
          emoji: '⚖️',
          impact: {'diversificationDemand': 0.3},
        ),
        QuizOption(
          label: '최대한 많은 섹터에 분산',
          emoji: '🌐',
          impact: {'diversificationDemand': 0.9},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q8_inflation',
      question: '인플레이션·물가상승이 걱정되세요?',
      subtitle: '걱정될수록 리츠/인프라 비중을 늘려드려요',
      options: [
        QuizOption(
          label: '많이 걱정돼요',
          description: '현금가치 떨어지는게 무서워요',
          emoji: '📈',
          impact: {'inflationHedge': 0.85},
        ),
        QuizOption(
          label: '조금은 걱정',
          emoji: '🤷',
          impact: {'inflationHedge': 0.2},
        ),
        QuizOption(
          label: '별로 신경 안 써요',
          emoji: '😌',
          impact: {'inflationHedge': -0.4},
        ),
      ],
    ),
  ];

  /// 답변 → PersonaProfile 변환
  /// answers: { questionId → [선택한 옵션 인덱스들] }
  static PersonaProfile buildProfile({
    required Map<String, List<int>> answers,
    required int monthlyTarget,
    required int budget,
    required List<String> preferredSectors,
  }) {
    final dimensions = <String, double>{
      'horizon': 0,
      'cashflowPreference': 0,
      'downsideTolerance': 0,
      'taxSensitivity': 0,
      'liquidityNeed': 0,
      'ethicsLooseness': 0,
      'diversificationDemand': 0,
      'inflationHedge': 0,
    };
    final excludeFlags = <String>{};

    for (final q in questions) {
      final selected = answers[q.id] ?? [];
      for (final idx in selected) {
        if (idx < 0 || idx >= q.options.length) continue;
        q.options[idx].impact.forEach((key, value) {
          if (key.startsWith('_exclude_')) {
            if (value > 0) excludeFlags.add(key);
          } else if (dimensions.containsKey(key)) {
            dimensions[key] = dimensions[key]! + value;
          }
        });
      }
    }

    // [-1, 1] 범위로 클립
    dimensions.updateAll((_, v) => v.clamp(-1.0, 1.0));

    // 제외 플래그 → 섹터 코드 매핑
    final excludedSectors = <String>[];
    if (excludeFlags.contains('_exclude_gambling')) excludedSectors.add('gambling');
    if (excludeFlags.contains('_exclude_defense')) excludedSectors.add('defense');
    if (excludeFlags.contains('_exclude_fossil')) excludedSectors.add('fossil');
    if (excludeFlags.contains('_exclude_consumer_sin')) excludedSectors.add('sin');

    return PersonaProfile(
      horizon: dimensions['horizon']!,
      cashflowPreference: dimensions['cashflowPreference']!,
      downsideTolerance: dimensions['downsideTolerance']!,
      taxSensitivity: dimensions['taxSensitivity']!,
      liquidityNeed: dimensions['liquidityNeed']!,
      ethicsLooseness: dimensions['ethicsLooseness']!,
      diversificationDemand: dimensions['diversificationDemand']!,
      inflationHedge: dimensions['inflationHedge']!,
      monthlyTarget: monthlyTarget,
      budget: budget,
      preferredSectors: preferredSectors,
      excludedSectors: excludedSectors,
    );
  }
}