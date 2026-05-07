/// ═══════════════════════════════════════════════════════════
///  Persona Profile — 사용자의 8차원 벡터
///
///  📝 멘트 수정은 이 파일 안의 QuizQuestion / QuizOption
///     label·subtitle·description 만 바꾸면 끝.
/// ═══════════════════════════════════════════════════════════

class PersonaProfile {
  final double horizon;
  final double cashflowPreference;
  final double downsideTolerance;
  final double taxSensitivity;
  final double liquidityNeed;
  final double ethicsLooseness;
  final double diversificationDemand;
  final double inflationHedge;

  final int monthlyTarget;
  final int budget;
  final List<String> preferredSectors;
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

  int get deterministicSeed {
    final v = [
      horizon, cashflowPreference, downsideTolerance, taxSensitivity,
      liquidityNeed, ethicsLooseness, diversificationDemand, inflationHedge,
      monthlyTarget / 1000000, budget / 100000000,
    ];
    int seed = 0;
    for (var i = 0; i < v.length; i++) {
      seed ^= ((v[i] * 1000).round() & 0xFFFF) << (i % 4);
    }
    return seed.abs();
  }

  List<double> get vector => [
    horizon, cashflowPreference, downsideTolerance, taxSensitivity,
    liquidityNeed, ethicsLooseness, diversificationDemand, inflationHedge,
  ];

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
  /// 차원별 영향도 — 예: {'horizon': -0.8, 'liquidityNeed': 0.5}
  final Map<String, double> impact;

  const QuizOption({
    required this.label,
    this.description,
    required this.impact,
  });
}

class QuizBank {
  static const List<QuizQuestion> questions = [
    QuizQuestion(
      id: 'q1_horizon',
      question: '월 배당 목표는 언제까지 채우고 싶나요?',
      subtitle: '시간이 길수록 성장주를 더 섞을 수 있어요',
      options: [
        QuizOption(
          label: '3년 안에',
          description: '빠르게 결과를 보고 싶음',
          impact: {'horizon': -0.9, 'cashflowPreference': -0.3},
        ),
        QuizOption(
          label: '5~7년',
          description: '적당한 속도로',
          impact: {'horizon': -0.2},
        ),
        QuizOption(
          label: '10년 이상',
          description: '천천히 복리로',
          impact: {'horizon': 0.6, 'downsideTolerance': 0.3},
        ),
        QuizOption(
          label: '15년 이상 / 은퇴 자금',
          description: '시간은 충분',
          impact: {'horizon': 0.95, 'inflationHedge': 0.5},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q2_cashflow',
      question: '배당금이 어떤 식으로 들어오면 좋을까요?',
      subtitle: '월급처럼 vs 보너스처럼',
      options: [
        QuizOption(
          label: '매달 균등하게',
          description: '월급처럼 비슷한 금액',
          impact: {'cashflowPreference': -0.9},
        ),
        QuizOption(
          label: '분기마다',
          description: '3개월 한 번 큼직하게',
          impact: {'cashflowPreference': -0.2},
        ),
        QuizOption(
          label: '연 1~2회 큰 금액',
          description: '보너스처럼 한 번에',
          impact: {'cashflowPreference': 0.7},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q3_downside',
      question: '내 주식이 한 달 만에 -30% 떨어졌어요. 어떡하나요?',
      subtitle: '솔직히 답해도 돼요. 정답은 없어요',
      options: [
        QuizOption(
          label: '바로 다 팔아요',
          description: '잠 못 자느니 손절',
          impact: {'downsideTolerance': -0.95, 'liquidityNeed': -0.6},
        ),
        QuizOption(
          label: '불안하지만 버텨요',
          description: '회복을 기대하면서',
          impact: {'downsideTolerance': -0.2},
        ),
        QuizOption(
          label: '오히려 더 사요',
          description: '싸게 살 기회',
          impact: {'downsideTolerance': 0.7, 'horizon': 0.3},
        ),
        QuizOption(
          label: '뉴스도 안 봐요',
          description: '신경 끄고 묻어둠',
          impact: {'downsideTolerance': 0.5, 'liquidityNeed': 0.6},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q4_tax',
      question: '예상 연 금융소득이 얼마쯤 되나요?',
      subtitle: '연 2,000만원 초과면 종합과세 대상',
      options: [
        QuizOption(
          label: '500만원 이하',
          impact: {'taxSensitivity': 0.6},
        ),
        QuizOption(
          label: '500~2,000만원',
          impact: {'taxSensitivity': 0.0},
        ),
        QuizOption(
          label: '2,000만원 초과',
          description: '종합과세는 피하고 싶음',
          impact: {'taxSensitivity': -0.9},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q5_liquidity',
      question: '갑자기 큰 돈 쓸 일이 생길 가능성은요?',
      subtitle: '결혼·이사·창업 등',
      options: [
        QuizOption(
          label: '1~2년 안에 가능성 있음',
          impact: {'liquidityNeed': -0.85, 'downsideTolerance': -0.3},
        ),
        QuizOption(
          label: '5년 정도는 안 건드릴 수 있음',
          impact: {'liquidityNeed': 0.3},
        ),
        QuizOption(
          label: '아예 묻어둘 자금',
          impact: {'liquidityNeed': 0.9, 'horizon': 0.4},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q6_ethics',
      question: '피하고 싶은 산업이 있나요?',
      subtitle: '복수 선택 가능',
      type: QuestionType.multiChoice,
      options: [
        QuizOption(
          label: '담배 / 주류',
          impact: {'ethicsLooseness': -0.4, '_exclude_consumer_sin': 1.0},
        ),
        QuizOption(
          label: '카지노 / 도박',
          impact: {'ethicsLooseness': -0.4, '_exclude_gambling': 1.0},
        ),
        QuizOption(
          label: '방산 / 무기',
          impact: {'ethicsLooseness': -0.3, '_exclude_defense': 1.0},
        ),
        QuizOption(
          label: '화석연료',
          impact: {'ethicsLooseness': -0.3, '_exclude_fossil': 1.0},
        ),
        QuizOption(
          label: '없음 / 수익이면 OK',
          impact: {'ethicsLooseness': 0.6},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q7_diversity',
      question: '한 산업에 집중 vs 여러 산업에 분산?',
      subtitle: '집중 = 수익률 ↑ 변동성 ↑',
      options: [
        QuizOption(
          label: '확신 있는 한두 섹터에 집중',
          impact: {'diversificationDemand': -0.7, 'downsideTolerance': 0.3},
        ),
        QuizOption(
          label: '3~4개 섹터에 골고루',
          impact: {'diversificationDemand': 0.3},
        ),
        QuizOption(
          label: '최대한 많은 섹터에 분산',
          impact: {'diversificationDemand': 0.9},
        ),
      ],
    ),
    QuizQuestion(
      id: 'q8_inflation',
      question: '물가 상승이 신경 쓰이나요?',
      subtitle: '신경 쓰일수록 리츠·인프라 비중을 올려요',
      options: [
        QuizOption(
          label: '많이 신경 써요',
          description: '현금 가치 떨어지는 게 싫음',
          impact: {'inflationHedge': 0.85},
        ),
        QuizOption(
          label: '조금은',
          impact: {'inflationHedge': 0.2},
        ),
        QuizOption(
          label: '별로',
          impact: {'inflationHedge': -0.4},
        ),
      ],
    ),
  ];

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

    dimensions.updateAll((_, v) => v.clamp(-1.0, 1.0));

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
