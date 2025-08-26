import 'package:flutter/material.dart';
import 'dart:io';

// Central localization service for Mindload
class AppLocalizations {
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('fr'), // French
    Locale('de'), // German
    Locale('it'), // Italian
    Locale('ja'), // Japanese
    Locale('ko'), // Korean
    Locale('zh', 'Hans'), // Chinese (Simplified)
    Locale('zh', 'Hant'), // Chinese (Traditional)
    Locale('ar'), // Arabic
    Locale('hi'), // Hindi
  ];

  final Locale locale;
  late final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale) {
    _localizedStrings = _getLocalizedStrings(locale);
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Get system locale with fallback
  static Locale getSystemLocale() {
    try {
      return Platform.localeName.isNotEmpty
          ? Locale.fromSubtags(languageCode: Platform.localeName.split('_')[0])
          : const Locale('en');
    } catch (e) {
      // Fallback to English if locale detection fails
      return const Locale('en');
    }
  }

  // Check if locale is RTL
  bool get isRTL => locale.languageCode == 'ar' || locale.languageCode == 'he';

  // Localized strings getters
  String get paywallHeader => _localizedStrings['paywall_header']!;
  String get monthlyBadge => _localizedStrings['monthly_badge']!;
  String get monthlySubtitle => _localizedStrings['monthly_subtitle']!;
  String get annualTitle => _localizedStrings['annual_title']!;
  String get annualSubtitle => _localizedStrings['annual_subtitle']!;
  String get annualSubtitleIntro => _localizedStrings['annual_subtitle_intro']!;
  String get primaryButton => _localizedStrings['primary_button']!;
  String get secondaryButton => _localizedStrings['secondary_button']!;
  String get privacyPolicy => _localizedStrings['privacy_policy']!;
  String get termsOfUse => _localizedStrings['terms_of_use']!;

  // Exit intent strings
  String get exitIntentTitle => _localizedStrings['exit_intent_title']!;
  String get exitIntentBody => _localizedStrings['exit_intent_body']!;
  String get exitIntentBuy => _localizedStrings['exit_intent_buy']!;
  String get exitIntentMaybe => _localizedStrings['exit_intent_maybe']!;

  // Feature bullets
  String get introCredits => _localizedStrings['intro_credits']!;
  String get priorityGeneration => _localizedStrings['priority_generation']!;
  String get adaptiveReminders => _localizedStrings['adaptive_reminders']!;

  // Settings/Subscription
  String get manageIos => _localizedStrings['manage_ios']!;
  String get manageAndroid => _localizedStrings['manage_android']!;
  String get currentTier => _localizedStrings['current_tier']!;
  String get remainingCredits => _localizedStrings['remaining_credits']!;
  String get renewalDate => _localizedStrings['renewal_date']!;
  String get accountDeletion => _localizedStrings['account_deletion']!;
  String get dataExport => _localizedStrings['data_export']!;

  // Purchase states
  String get purchasePending => _localizedStrings['purchase_pending']!;
  String get purchaseSuccess => _localizedStrings['purchase_success']!;
  String get purchaseFailed => _localizedStrings['purchase_failed']!;
  String get purchaseRestored => _localizedStrings['purchase_restored']!;
  String get noPurchasesFound => _localizedStrings['no_purchases_found']!;
  String get restoreFailed => _localizedStrings['restore_failed']!;

  // Regional compliance
  String get gdprNotice => _localizedStrings['gdpr_notice']!;
  String get dataProcessing => _localizedStrings['data_processing']!;
  String get contactSupport => _localizedStrings['contact_support']!;

  // Theme and accessibility
  String? get themeSelector => _localizedStrings['theme_selector'];
  String? get appearance => _localizedStrings['appearance'];
  String? get chooseYourPreferredTheme =>
      _localizedStrings['choose_your_preferred_theme'];
  String? get cancel => _localizedStrings['cancel'];
  String? get apply => _localizedStrings['apply'];

  // Get localized strings for given locale
  Map<String, String> _getLocalizedStrings(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return _spanishStrings;
      case 'pt':
        return _portugueseStrings;
      case 'fr':
        return _frenchStrings;
      case 'de':
        return _germanStrings;
      case 'it':
        return _italianStrings;
      case 'ja':
        return _japaneseStrings;
      case 'ko':
        return _koreanStrings;
      case 'zh':
        return locale.countryCode == 'Hant'
            ? _chineseTraditionalStrings
            : _chineseSimplifiedStrings;
      case 'ar':
        return _arabicStrings;
      case 'hi':
        return _hindiStrings;
      default:
        return _englishStrings;
    }
  }

  // English (default)
  static const Map<String, String> _englishStrings = {
    'paywall_header': 'Unlock Axon Monthly for Focused Wins',
    'monthly_badge': r'$4.99/month',
    'monthly_subtitle': r'120 MindLoad Tokens/month, cancel anytime',
    'annual_title': r'$49.99/year — Save 28%',
    'annual_subtitle': 'Best value with annual savings',
    'annual_subtitle_intro': r'$39.99 first year, then $49.99',
    'primary_button': 'Start Axon Monthly',
    'secondary_button': 'Restore Purchases',
    'privacy_policy': 'Privacy Policy',
    'terms_of_use': 'Terms of Use',
    'exit_intent_title': 'Not ready to subscribe?',
    'exit_intent_body': r'Spark Pack $2.99 → +50 MindLoad Tokens',
    'exit_intent_buy': 'Buy Spark Pack',
    'exit_intent_maybe': 'Maybe Later',
    'intro_credits': '20 MindLoad Tokens/month',
    'priority_generation': 'Priority generation',
    'adaptive_reminders': 'Adaptive reminders',
    'manage_ios': 'Manage in App Store',
    'manage_android': 'Manage in Google Play',
    'current_tier': 'Current Plan',
    'remaining_credits': 'Remaining Credits',
    'renewal_date': 'Renews',
    'account_deletion': 'Delete Account',
    'data_export': 'Export My Data',
    'purchase_pending': 'Processing purchase...',
    'purchase_success': 'Purchase successful!',
    'purchase_failed': 'Purchase failed. Please try again.',
    'purchase_restored': 'Purchases restored successfully',
    'no_purchases_found': 'No purchases found to restore',
    'restore_failed': 'Restore failed. Please try again.',
    'gdpr_notice': 'We respect your privacy and comply with GDPR',
    'data_processing': 'Learn about our data processing',
    'contact_support': 'Contact Support',

    // Theme and accessibility
    'theme_selector': 'Theme selector',
    'appearance': 'Appearance',
    'choose_your_preferred_theme': 'Choose your preferred theme',
    'cancel': 'Cancel',
    'apply': 'Apply',
  };

  // Spanish
  static const Map<String, String> _spanishStrings = {
    'paywall_header': 'Desbloquea Axon Mensual para Victorias Enfocadas',
    'monthly_badge': r'$4.99/mes',
    'monthly_subtitle': r'120 MindLoad Tokens/mes, cancela cuando quieras',
    'annual_title': r'$49.99/año — Ahorra 28%',
    'annual_subtitle': 'Mejor valor con ahorro anual',
    'annual_subtitle_intro': r'$39.99 primer año, luego $49.99',
    'primary_button': 'Empezar Axon Mensual',
    'secondary_button': 'Restaurar Compras',
    'privacy_policy': 'Política de Privacidad',
    'terms_of_use': 'Términos de Uso',
    'exit_intent_title': '¿No estás listo para suscribirte?',
    'exit_intent_body': r'Spark Pack $2.99 → +50 MindLoad Tokens',
    'exit_intent_buy': 'Comprar Spark Pack',
    'exit_intent_maybe': 'Tal vez después',
    'intro_credits': '20 MindLoad Tokens/mes',
    'priority_generation': 'Generación prioritaria',
    'adaptive_reminders': 'Recordatorios adaptativos',
    'manage_ios': 'Gestionar en App Store',
    'manage_android': 'Gestionar en Google Play',
    'current_tier': 'Plan Actual',
    'remaining_credits': 'Créditos Restantes',
    'renewal_date': 'Se Renueva',
    'account_deletion': 'Eliminar Cuenta',
    'data_export': 'Exportar Mis Datos',
    'purchase_pending': 'Procesando compra...',
    'purchase_success': '¡Compra exitosa!',
    'purchase_failed': 'Compra fallida. Inténtalo de nuevo.',
    'purchase_restored': 'Compras restauradas exitosamente',
    'no_purchases_found': 'No se encontraron compras para restaurar',
    'restore_failed': 'Restauración fallida. Inténtalo de nuevo.',
    'gdpr_notice': 'Respetamos tu privacidad y cumplimos con GDPR',
    'data_processing': 'Conoce sobre nuestro procesamiento de datos',
    'contact_support': 'Contactar Soporte',

    // Theme and accessibility
    'theme_selector': 'Selector de tema',
    'appearance': 'Apariencia',
    'choose_your_preferred_theme': 'Elige tu tema preferido',
    'cancel': 'Cancelar',
    'apply': 'Aplicar',
  };

  // Portuguese (Brazil)
  static const Map<String, String> _portugueseStrings = {
    'paywall_header': 'Desbloqueie o Pro para Vitórias Focadas',
    'monthly_badge': r'$2.99 primeiro mês',
    'monthly_subtitle': r'depois $6.99/mês, cancele a qualquer momento',
    'annual_title': r'$49.99/ano — Economize 28%',
    'annual_subtitle': 'Melhor valor com economia anual',
    'annual_subtitle_intro': r'$39.99 primeiro ano, depois $49.99',
    'primary_button': 'Começar Pro',
    'secondary_button': 'Restaurar Compras',
    'privacy_policy': 'Política de Privacidade',
    'terms_of_use': 'Termos de Uso',
    'exit_intent_title': 'Não está pronto para assinar?',
    'exit_intent_body': r'Pacote Inicial $1.99 → +100 créditos',
    'exit_intent_buy': 'Comprar Pacote Inicial',
    'exit_intent_maybe': 'Talvez depois',
    'intro_credits': '30 créditos iniciais',
    'priority_generation': 'Geração prioritária',
    'adaptive_reminders': 'Lembretes adaptativos',
    'manage_ios': 'Gerenciar na App Store',
    'manage_android': 'Gerenciar no Google Play',
    'current_tier': 'Plano Atual',
    'remaining_credits': 'Créditos Restantes',
    'renewal_date': 'Renova em',
    'account_deletion': 'Excluir Conta',
    'data_export': 'Exportar Meus Dados',
    'purchase_pending': 'Processando compra...',
    'purchase_success': 'Compra bem-sucedida!',
    'purchase_failed': 'Compra falhou. Tente novamente.',
    'purchase_restored': 'Compras restauradas com sucesso',
    'no_purchases_found': 'Nenhuma compra encontrada para restaurar',
    'restore_failed': 'Restauração falhou. Tente novamente.',
    'gdpr_notice': 'Respeitamos sua privacidade e cumprimos com a LGPD',
    'data_processing': 'Saiba sobre nosso processamento de dados',
    'contact_support': 'Contatar Suporte',
  };

  // French
  static const Map<String, String> _frenchStrings = {
    'paywall_header': 'Débloquez Pro pour des Victoires Concentrées',
    'monthly_badge': r'0,99$ premier mois',
    'monthly_subtitle': r'puis 6,99$/mois, annulez à tout moment',
    'annual_title': r'49,99$/an — Économisez 28%',
    'annual_subtitle': 'Meilleure valeur avec économies annuelles',
    'annual_subtitle_intro': r'39,99$ première année, puis 49,99$',
    'primary_button': 'Commencer Pro',
    'secondary_button': 'Restaurer Achats',
    'privacy_policy': 'Politique de Confidentialité',
    'terms_of_use': "Conditions d'Utilisation",
    'exit_intent_title': 'Pas prêt à vous abonner?',
    'exit_intent_body': r'Pack Logique 1,99$ → +100 crédits',
    'exit_intent_buy': 'Acheter Pack Logique',
    'exit_intent_maybe': 'Peut-être plus tard',
    'intro_credits': '30 crédits d\'introduction',
    'priority_generation': 'Génération prioritaire',
    'adaptive_reminders': 'Rappels adaptatifs',
    'manage_ios': "Gérer dans l'App Store",
    'manage_android': 'Gérer dans Google Play',
    'current_tier': 'Plan Actuel',
    'remaining_credits': 'Crédits Restants',
    'renewal_date': 'Se Renouvelle',
    'account_deletion': 'Supprimer le Compte',
    'data_export': 'Exporter Mes Données',
    'purchase_pending': 'Traitement de l\'achat...',
    'purchase_success': 'Achat réussi!',
    'purchase_failed': 'Achat échoué. Veuillez réessayer.',
    'purchase_restored': 'Achats restaurés avec succès',
    'no_purchases_found': 'Aucun achat trouvé à restaurer',
    'restore_failed': 'Restauration échouée. Veuillez réessayer.',
    'gdpr_notice':
        'Nous respectons votre vie privée et nous nous conformons au RGPD',
    'data_processing': 'En savoir plus sur notre traitement des données',
    'contact_support': 'Contacter le Support',
  };

  // German
  static const Map<String, String> _germanStrings = {
    'paywall_header': 'Pro für fokussierte Siege freischalten',
    'monthly_badge': r'0,99$ erster Monat',
    'monthly_subtitle': r'dann 6,99$/Monat, jederzeit kündbar',
    'annual_title': r'49,99$/Jahr — Sparen Sie 28%',
    'annual_subtitle': 'Bester Wert mit jährlichen Ersparnissen',
    'annual_subtitle_intro': r'39,99$ erstes Jahr, dann 49,99$',
    'primary_button': 'Pro starten',
    'secondary_button': 'Käufe wiederherstellen',
    'privacy_policy': 'Datenschutzrichtlinie',
    'terms_of_use': 'Nutzungsbedingungen',
    'exit_intent_title': 'Noch nicht bereit zum Abonnieren?',
    'exit_intent_body': r'Logic-Paket 1,99$ → +100 Credits',
    'exit_intent_buy': 'Logic-Paket kaufen',
    'exit_intent_maybe': 'Vielleicht später',
    'intro_credits': '30 Intro-Credits',
    'priority_generation': 'Prioritätsgenerierung',
    'adaptive_reminders': 'Adaptive Erinnerungen',
    'manage_ios': 'Im App Store verwalten',
    'manage_android': 'In Google Play verwalten',
    'current_tier': 'Aktueller Plan',
    'remaining_credits': 'Verbleibende Credits',
    'renewal_date': 'Verlängert sich',
    'account_deletion': 'Konto löschen',
    'data_export': 'Meine Daten exportieren',
    'purchase_pending': 'Kauf wird verarbeitet...',
    'purchase_success': 'Kauf erfolgreich!',
    'purchase_failed': 'Kauf fehlgeschlagen. Bitte erneut versuchen.',
    'purchase_restored': 'Käufe erfolgreich wiederhergestellt',
    'no_purchases_found': 'Keine Käufe zum Wiederherstellen gefunden',
    'restore_failed':
        'Wiederherstellung fehlgeschlagen. Bitte erneut versuchen.',
    'gdpr_notice':
        'Wir respektieren Ihre Privatsphäre und halten uns an die DSGVO',
    'data_processing': 'Erfahren Sie mehr über unsere Datenverarbeitung',
    'contact_support': 'Support kontaktieren',
  };

  // Italian
  static const Map<String, String> _italianStrings = {
    'paywall_header': 'Sblocca Pro per Vittorie Focalizzate',
    'monthly_badge': r'0,99$ primo mese',
    'monthly_subtitle': r'poi 6,99$/mese, cancella in qualsiasi momento',
    'annual_title': r'49,99$/anno — Risparmia 28%',
    'annual_subtitle': 'Miglior valore con risparmio annuale',
    'annual_subtitle_intro': r'39,99$ primo anno, poi 49,99$',
    'primary_button': 'Inizia Pro',
    'secondary_button': 'Ripristina Acquisti',
    'privacy_policy': 'Privacy Policy',
    'terms_of_use': 'Termini di Utilizzo',
    'exit_intent_title': 'Non pronto ad abbonarti?',
    'exit_intent_body': r'Pacchetto Logic 1,99$ → +100 crediti',
    'exit_intent_buy': 'Compra Pacchetto Logic',
    'exit_intent_maybe': 'Forse dopo',
    'intro_credits': '30 crediti introduttivi',
    'priority_generation': 'Generazione prioritaria',
    'adaptive_reminders': 'Promemoria adattivi',
    'manage_ios': "Gestisci nell'App Store",
    'manage_android': 'Gestisci in Google Play',
    'current_tier': 'Piano Attuale',
    'remaining_credits': 'Crediti Rimanenti',
    'renewal_date': 'Si Rinnova',
    'account_deletion': 'Elimina Account',
    'data_export': 'Esporta i Miei Dati',
    'purchase_pending': 'Elaborazione acquisto...',
    'purchase_success': 'Acquisto riuscito!',
    'purchase_failed': 'Acquisto fallito. Riprova.',
    'purchase_restored': 'Acquisti ripristinati con successo',
    'no_purchases_found': 'Nessun acquisto trovato da ripristinare',
    'restore_failed': 'Ripristino fallito. Riprova.',
    'gdpr_notice': 'Rispettiamo la tua privacy e ci conformiamo al GDPR',
    'data_processing': 'Scopri di più sul nostro trattamento dei dati',
    'contact_support': 'Contatta il Supporto',
  };

  // Japanese
  static const Map<String, String> _japaneseStrings = {
    'paywall_header': '集中した勝利のためにProをアンロック',
    'monthly_badge': r'最初の月$2.99',
    'monthly_subtitle': r'その後$6.99/月、いつでもキャンセル',
    'annual_title': r'$49.99/年 — 28%節約',
    'annual_subtitle': '年間節約で最高の価値',
    'annual_subtitle_intro': r'最初の年$39.99、その後$49.99',
    'primary_button': 'Proを開始',
    'secondary_button': '購入を復元',
    'privacy_policy': 'プライバシーポリシー',
    'terms_of_use': '利用規約',
    'exit_intent_title': 'まだ購読の準備はできていませんか？',
    'exit_intent_body': r'スターターパック$1.99 → +100クレジット',
    'exit_intent_buy': 'スターターパックを購入',
    'exit_intent_maybe': '後で',
    'intro_credits': '30の導入クレジット',
    'priority_generation': '優先生成',
    'adaptive_reminders': 'アダプティブリマインダー',
    'manage_ios': 'App Storeで管理',
    'manage_android': 'Google Playで管理',
    'current_tier': '現在のプラン',
    'remaining_credits': '残りクレジット',
    'renewal_date': '更新日',
    'account_deletion': 'アカウントを削除',
    'data_export': 'データをエクスポート',
    'purchase_pending': '購入を処理中...',
    'purchase_success': '購入成功！',
    'purchase_failed': '購入に失敗しました。もう一度お試しください。',
    'purchase_restored': '購入が正常に復元されました',
    'no_purchases_found': '復元する購入が見つかりません',
    'restore_failed': '復元に失敗しました。もう一度お試しください。',
    'gdpr_notice': 'プライバシーを尊重し、GDPRに準拠しています',
    'data_processing': 'データ処理について詳しく見る',
    'contact_support': 'サポートに問い合わせ',
  };

  // Korean
  static const Map<String, String> _koreanStrings = {
    'paywall_header': '집중된 승리를 위해 Pro 잠금 해제',
    'monthly_badge': r'첫 달 $2.99',
    'monthly_subtitle': r'그 후 월 $6.99, 언제든지 취소',
    'annual_title': r'연 $49.99 — 28% 절약',
    'annual_subtitle': '연간 절약으로 최고의 가치',
    'annual_subtitle_intro': r'첫 해 $39.99, 그 후 $49.99',
    'primary_button': 'Pro 시작',
    'secondary_button': '구매 복원',
    'privacy_policy': '개인정보보호정책',
    'terms_of_use': '이용약관',
    'exit_intent_title': '구독할 준비가 되지 않았나요?',
    'exit_intent_body': r'로직 팩 $1.99 → +100 크레딧',
    'exit_intent_buy': '로직 팩 구매',
    'exit_intent_maybe': '나중에',
    'intro_credits': '30개의 소개 크레딧',
    'priority_generation': '우선 생성',
    'adaptive_reminders': '적응형 알림',
    'manage_ios': 'App Store에서 관리',
    'manage_android': 'Google Play에서 관리',
    'current_tier': '현재 플랜',
    'remaining_credits': '남은 크레딧',
    'renewal_date': '갱신 날짜',
    'account_deletion': '계정 삭제',
    'data_export': '내 데이터 내보내기',
    'purchase_pending': '구매 처리 중...',
    'purchase_success': '구매 성공!',
    'purchase_failed': '구매 실패. 다시 시도해 주세요.',
    'purchase_restored': '구매가 성공적으로 복원되었습니다',
    'no_purchases_found': '복원할 구매를 찾을 수 없습니다',
    'restore_failed': '복원 실패. 다시 시도해 주세요.',
    'gdpr_notice': '개인정보를 존중하며 GDPR을 준수합니다',
    'data_processing': '데이터 처리에 대해 자세히 알아보기',
    'contact_support': '지원팀 문의',
  };

  // Chinese Simplified
  static const Map<String, String> _chineseSimplifiedStrings = {
    'paywall_header': '解锁Pro专注胜利',
    'monthly_badge': r'首月$2.99',
    'monthly_subtitle': r'然后$6.99/月，随时取消',
    'annual_title': r'$49.99/年 — 节省28%',
    'annual_subtitle': '年度节省最佳价值',
    'annual_subtitle_intro': r'首年$39.99，然后$49.99',
    'primary_button': '开始Pro',
    'secondary_button': '恢复购买',
    'privacy_policy': '隐私政策',
    'terms_of_use': '使用条款',
    'exit_intent_title': '还没准备好订阅？',
    'exit_intent_body': r'逻辑包$1.99 → +100积分',
    'exit_intent_buy': '购买逻辑包',
    'exit_intent_maybe': '稍后再说',
    'intro_credits': '30个入门积分',
    'priority_generation': '优先生成',
    'adaptive_reminders': '自适应提醒',
    'manage_ios': '在App Store管理',
    'manage_android': '在Google Play管理',
    'current_tier': '当前计划',
    'remaining_credits': '剩余积分',
    'renewal_date': '续费日期',
    'account_deletion': '删除账户',
    'data_export': '导出我的数据',
    'purchase_pending': '处理购买中...',
    'purchase_success': '购买成功！',
    'purchase_failed': '购买失败。请重试。',
    'purchase_restored': '购买恢复成功',
    'no_purchases_found': '未找到可恢复的购买',
    'restore_failed': '恢复失败。请重试。',
    'gdpr_notice': '我们尊重您的隐私并遵守GDPR',
    'data_processing': '了解我们的数据处理',
    'contact_support': '联系支持',
  };

  // Chinese Traditional
  static const Map<String, String> _chineseTraditionalStrings = {
    'paywall_header': '解鎖Pro專注勝利',
    'monthly_badge': r'首月$2.99',
    'monthly_subtitle': r'然後$6.99/月，隨時取消',
    'annual_title': r'$49.99/年 — 節省28%',
    'annual_subtitle': '年度節省最佳價值',
    'annual_subtitle_intro': r'首年$39.99，然後$49.99',
    'primary_button': '開始Pro',
    'secondary_button': '恢復購買',
    'privacy_policy': '隱私政策',
    'terms_of_use': '使用條款',
    'exit_intent_title': '還沒準備好訂閱？',
    'exit_intent_body': r'邏輯包$1.99 → +100積分',
    'exit_intent_buy': '購買邏輯包',
    'exit_intent_maybe': '稍後再說',
    'intro_credits': '30個入門積分',
    'priority_generation': '優先生成',
    'adaptive_reminders': '自適應提醒',
    'manage_ios': '在App Store管理',
    'manage_android': '在Google Play管理',
    'current_tier': '當前計劃',
    'remaining_credits': '剩餘積分',
    'renewal_date': '續費日期',
    'account_deletion': '刪除賬戶',
    'data_export': '導出我的數據',
    'purchase_pending': '處理購買中...',
    'purchase_success': '購買成功！',
    'purchase_failed': '購買失敗。請重試。',
    'purchase_restored': '購買恢復成功',
    'no_purchases_found': '未找到可恢復的購買',
    'restore_failed': '恢復失敗。請重試。',
    'gdpr_notice': '我們尊重您的隱私並遵守GDPR',
    'data_processing': '了解我們的數據處理',
    'contact_support': '聯繫支持',
  };

  // Arabic (RTL)
  static const Map<String, String> _arabicStrings = {
    'paywall_header': 'افتح Pro للانتصارات المركزة',
    'monthly_badge': '2.99 دولار الشهر الأول',
    'monthly_subtitle': 'ثم 6.99 دولار/شهر، إلغاء في أي وقت',
    'annual_title': '49.99 دولار/سنة — وفر 28%',
    'annual_subtitle': 'أفضل قيمة مع التوفير السنوي',
    'annual_subtitle_intro': '39.99 دولار السنة الأولى، ثم 49.99 دولار',
    'primary_button': 'ابدأ Pro',
    'secondary_button': 'استعادة المشتريات',
    'privacy_policy': 'سياسة الخصوصية',
    'terms_of_use': 'شروط الاستخدام',
    'exit_intent_title': 'لست مستعداً للاشتراك؟',
    'exit_intent_body': 'حزمة البداية 1.99 دولار ← +100 رصيد',
    'exit_intent_buy': 'شراء حزمة البداية',
    'exit_intent_maybe': 'ربما لاحقاً',
    'intro_credits': '30 رصيد تمهيدي',
    'priority_generation': 'توليد مُرجح',
    'adaptive_reminders': 'تذكيرات تكيفية',
    'manage_ios': 'إدارة في App Store',
    'manage_android': 'إدارة في Google Play',
    'current_tier': 'الخطة الحالية',
    'remaining_credits': 'الرصيد المتبقي',
    'renewal_date': 'تاريخ التجديد',
    'account_deletion': 'حذف الحساب',
    'data_export': 'تصدير بياناتي',
    'purchase_pending': 'معالجة الشراء...',
    'purchase_success': 'تم الشراء بنجاح!',
    'purchase_failed': 'فشل الشراء. حاول مرة أخرى.',
    'purchase_restored': 'تم استعادة المشتريات بنجاح',
    'no_purchases_found': 'لم يتم العثور على مشتريات للاستعادة',
    'restore_failed': 'فشلت الاستعادة. حاول مرة أخرى.',
    'gdpr_notice': 'نحن نحترم خصوصيتك ونمتثل لـ GDPR',
    'data_processing': 'تعرف على معالجة البيانات لدينا',
    'contact_support': 'اتصل بالدعم',

    // Theme and accessibility
    'theme_selector': 'منتقي المظهر',
    'appearance': 'المظهر',
    'choose_your_preferred_theme': 'اختر المظهر المفضل لديك',
    'cancel': 'إلغاء',
    'apply': 'تطبيق',
  };

  // Hindi
  static const Map<String, String> _hindiStrings = {
    'paywall_header': 'फोकस्ड जीत के लिए Pro अनलॉक करें',
    'monthly_badge': r'पहला महीना $2.99',
    'monthly_subtitle': r'फिर $6.99/महीना, कभी भी रद्द करें',
    'annual_title': r'$49.99/साल — 28% बचाएं',
    'annual_subtitle': 'वार्षिक बचत के साथ सबसे अच्छा मूल्य',
    'annual_subtitle_intro': r'पहला साल $39.99, फिर $49.99',
    'primary_button': 'Pro शुरू करें',
    'secondary_button': 'खरीदारी पुनर्स्थापित करें',
    'privacy_policy': 'गोपनीयता नीति',
    'terms_of_use': 'उपयोग की शर्तें',
    'exit_intent_title': 'सब्सक्राइब करने के लिए तैयार नहीं हैं?',
    'exit_intent_body': r'लॉजिक पैक $1.99 → +100 क्रेडिट',
    'exit_intent_buy': 'लॉजिक पैक खरीदें',
    'exit_intent_maybe': 'शायद बाद में',
    'intro_credits': '30 परिचय क्रेडिट',
    'priority_generation': 'प्राथमिकता जनरेशन',
    'adaptive_reminders': 'अनुकूली रिमाइंडर',
    'manage_ios': 'App Store में प्रबंधित करें',
    'manage_android': 'Google Play में प्रबंधित करें',
    'current_tier': 'वर्तमान योजना',
    'remaining_credits': 'शेष क्रेडिट',
    'renewal_date': 'नवीनीकरण तिथि',
    'account_deletion': 'खाता हटाएं',
    'data_export': 'मेरा डेटा निर्यात करें',
    'purchase_pending': 'खरीदारी प्रसंस्करण...',
    'purchase_success': 'खरीदारी सफल!',
    'purchase_failed': 'खरीदारी विफल। कृपया पुनः प्रयास करें।',
    'purchase_restored': 'खरीदारी सफलतापूर्वक पुनर्स्थापित',
    'no_purchases_found': 'पुनर्स्थापित करने के लिए कोई खरीदारी नहीं मिली',
    'restore_failed': 'पुनर्स्थापना विफल। कृपया पुनः प्रयास करें।',
    'gdpr_notice':
        'हम आपकी गोपनीयता का सम्मान करते हैं और GDPR का पालन करते हैं',
    'data_processing': 'हमारे डेटा प्रोसेसिंग के बारे में जानें',
    'contact_support': 'सहायता से संपर्क करें',
  };

  // Format localized date
  String formatDate(DateTime date) {
    try {
      // Use system locale for date formatting
      if (locale.languageCode == 'ja') {
        return '${date.year}年${date.month}月${date.day}日';
      } else if (locale.languageCode == 'ko') {
        return '${date.year}년 ${date.month}월 ${date.day}일';
      } else if (locale.languageCode == 'zh') {
        return '${date.year}年${date.month}月${date.day}日';
      } else if (locale.languageCode == 'ar') {
        return '${date.day}/${date.month}/${date.year}';
      } else if (locale.languageCode == 'en') {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Format numbers with locale-specific formatting
  String formatNumber(int number) {
    if (locale.languageCode == 'ar') {
      // Use Arabic-Indic numerals for Arabic
      const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return number.toString().split('').map((char) {
        final digit = int.tryParse(char);
        return digit != null ? arabicNumerals[digit] : char;
      }).join('');
    }
    return number.toString();
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode &&
        (supportedLocale.countryCode == null ||
            supportedLocale.countryCode == locale.countryCode));
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
