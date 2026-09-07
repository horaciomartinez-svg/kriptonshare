// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'KRIPTONSHARE';

  @override
  String get cancel => 'Cancelar';

  @override
  String get accept => 'Aceitar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get delete => 'Excluir';

  @override
  String get share => 'Compartilhar';

  @override
  String get revoke => 'Revogar';

  @override
  String get dataRoom => 'Data Room';

  @override
  String get premium => 'Premium';

  @override
  String get premiumBadge => 'PREMIUM';

  @override
  String get free => 'Grátis';

  @override
  String get enabled => 'Ativado';

  @override
  String get disabled => 'Desativado';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get splashTagline => 'Data Room Efêmero';

  @override
  String get onboardingTitle1 => 'Criptografia Zero-Knowledge';

  @override
  String get onboardingBody1 =>
      'Seus arquivos são criptografados localmente com AES-256 antes de serem enviados para a nuvem. Ninguém além de você possui as chaves.';

  @override
  String get onboardingTitle2 => 'Links Efêmeros';

  @override
  String get onboardingBody2 =>
      'Configure a autodestruição física dos seus documentos. Escolha a duração exata de validade do link de acesso seguro.';

  @override
  String get onboardingTitle3 => 'Segurança Forense';

  @override
  String get onboardingBody3 =>
      'Mitigue a espionagem corporativa e os vazamentos físicos com marcas d\'água dinâmicas e bloqueio de capturas de tela.';

  @override
  String get onboardingSkip => 'PULAR';

  @override
  String get onboardingStart => 'COMEÇAR';

  @override
  String get onboardingNext => 'PRÓXIMO';

  @override
  String get authTagline => 'Seu dispositivo é o único guardião';

  @override
  String get loginTab => 'Entrar';

  @override
  String get registerTab => 'Criar conta';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'voce@email.com';

  @override
  String get emailRequired => 'E-mail obrigatório';

  @override
  String get emailInvalid => 'E-mail inválido';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordRequired => 'Senha obrigatória';

  @override
  String passwordMinLength(int min) {
    return 'Mínimo de $min caracteres';
  }

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get confirmPasswordRequired => 'Confirmação obrigatória';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get loginButton => 'Entrar';

  @override
  String get registerButton => 'Criar conta grátis';

  @override
  String get loginInvalidCredentials =>
      'Credenciais inválidas. Tente novamente.';

  @override
  String get registerError => 'Erro ao criar conta. Tente outro e-mail.';

  @override
  String get biometricLoginReason =>
      'Verifique sua identidade para concluir o login';

  @override
  String get biometricAuthCancelled => 'Autenticação biométrica cancelada.';

  @override
  String freePlanInfo(int maxMB, int maxLinks, int maxHours) {
    return 'Plano gratuito: $maxMB MB máx. · $maxLinks links/mês · ${maxHours}h de duração';
  }

  @override
  String get termsNotice =>
      'Ao se registrar, você aceita os termos de soberania de dados. A KRIPTONSHARE nunca armazena seus arquivos em texto simples.';

  @override
  String get lockTitle => 'KRIPTONSHARE bloqueado';

  @override
  String get lockSubtitle => 'Use sua digital ou rosto para desbloquear o app.';

  @override
  String get lockVerifying => 'Verificando...';

  @override
  String get unlockWithBiometrics => 'Desbloquear com biometria';

  @override
  String get signOut => 'Sair';

  @override
  String get authCancelled => 'Autenticação cancelada.';

  @override
  String get noSavedCredentials =>
      'Não há credenciais salvas. Faça login manualmente.';

  @override
  String get invalidSavedCredentials =>
      'As credenciais salvas não são mais válidas. Faça login manualmente.';

  @override
  String get biometricSettingsTitle => 'Configuração de Biometria';

  @override
  String get biometricIntro =>
      'Proteja o acesso aos seus Data Rooms com sua identidade biométrica.';

  @override
  String get biometricNotAvailableTitle => 'Biometria não disponível';

  @override
  String get biometricNoSensorsBody =>
      'Este dispositivo não possui sensores biométricos configurados.';

  @override
  String get testNow => 'Testar agora';

  @override
  String get verifyAgain => 'Verificar novamente';

  @override
  String get biometricUnlock => 'Desbloqueio biométrico';

  @override
  String get dataSovereigntyTitle => 'Soberania de dados';

  @override
  String get dataSovereigntyBody =>
      'Sua digital ou rosto nunca saem do dispositivo. Não armazenamos dados biométricos.';

  @override
  String get quickAccessTitle => 'Acesso rápido';

  @override
  String get quickAccessBody =>
      'Desbloqueie a KRIPTONSHARE sem digitar sua senha toda vez.';

  @override
  String get extraProtectionTitle => 'Proteção adicional';

  @override
  String get extraProtectionBody =>
      'A biometria complementa sua senha; não a substitui.';

  @override
  String get securityTitle => 'Segurança';

  @override
  String get faceId => 'Face ID';

  @override
  String get iris => 'Íris';

  @override
  String get fingerprint => 'Digital';

  @override
  String get faceIdDescription =>
      'Use o Face ID para desbloquear a KRIPTONSHARE com segurança.';

  @override
  String get irisDescription => 'Use o reconhecimento de íris para acessar.';

  @override
  String get fingerprintDescription =>
      'Use sua digital para desbloquear o app rapidamente.';

  @override
  String get biometricEnableReason =>
      'Confirme sua digital ou rosto para ativar o desbloqueio biométrico';

  @override
  String get biometricAuthSuccess => 'Autenticação biométrica bem-sucedida.';

  @override
  String get biometricEnableCancelled =>
      'Não foi possível ativar: autenticação cancelada.';

  @override
  String get biometricUnlockEnabledMsg =>
      'Desbloqueio biométrico ativado. Será solicitado após o login.';

  @override
  String get biometricUnlockDisabledMsg => 'Desbloqueio biométrico desativado.';

  @override
  String biometricQueryError(String message) {
    return 'Erro ao consultar a biometria: $message';
  }

  @override
  String get dashboardTab => 'Painel';

  @override
  String get linksTab => 'Links';

  @override
  String get profileTab => 'Perfil';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get capacity => 'Capacidade';

  @override
  String get duration => 'Duração';

  @override
  String get plan => 'Plano';

  @override
  String get receivedFiles => 'Arquivos recebidos';

  @override
  String get noReceivedFiles => 'Você não recebeu arquivos';

  @override
  String get receivedFilesHint =>
      'Os links enviados para seu e-mail aparecerão aqui';

  @override
  String get activeLinks => 'Links ativos';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get noActiveLinks => 'Sem links ativos';

  @override
  String get createFirstDataRoom => 'Crie seu primeiro Data Room seguro';

  @override
  String get expiresLabel => 'Expira';

  @override
  String expiresInMinutes(int minutes) {
    return 'em ${minutes}min';
  }

  @override
  String expiresInHours(int hours) {
    return 'em ${hours}h';
  }

  @override
  String expiresInDays(int days) {
    return 'em ${days}d';
  }

  @override
  String get analyticsTooltip => 'Análises';

  @override
  String get newDataRoom => 'Novo Data Room';

  @override
  String get attachFile => 'Anexar Arquivo';

  @override
  String get cameraToVault => 'Câmera para o Vault';

  @override
  String get noPublicGallery => 'Sem galeria pública';

  @override
  String get encryptionPasswordLabel => 'Senha de criptografia';

  @override
  String get passwordNotStoredHint => 'Não é armazenada na nuvem';

  @override
  String get recipientEmailOptional => 'E-mail do destinatário (opcional)';

  @override
  String get encryptAndGenerateLink => 'Criptografar e gerar link';

  @override
  String get dataRoomReadyBanner => 'Data Room pronto na Cloudflare';

  @override
  String get protectingFiles => 'Protegendo seus arquivos...';

  @override
  String get encryptingAesStep => '> Criptografando com AES-256...';

  @override
  String get syncingR2Step => '> Sincronizando com o R2...';

  @override
  String fileExceedsPlanLimit(String maxSize) {
    return 'O arquivo excede o limite de $maxSize do seu plano';
  }

  @override
  String captureExceedsPlanLimit(String maxSize) {
    return 'A captura excede o limite de $maxSize do seu plano';
  }

  @override
  String get cameraAccessCancelled => 'Acesso à câmera cancelado ou negado';

  @override
  String get enterEncryptionPassword => 'Digite uma senha de criptografia';

  @override
  String get sessionExpired => 'Sessão expirada';

  @override
  String get filePickError => 'Erro ao selecionar arquivo';

  @override
  String get shareDataRoomTitle => 'Data Room Confidencial Compartilhado';

  @override
  String get expirationLabel => 'Expiração:';

  @override
  String get oneHour => '1 hora';

  @override
  String get default24h => '24h (Padrão)';

  @override
  String get max48Hours => '48 horas (Máx.)';

  @override
  String get max30Days => 'Máx. 30 dias';

  @override
  String daysUnit(int count) {
    return '$count Dias';
  }

  @override
  String hoursUnit(int count) {
    return '$count Horas';
  }

  @override
  String linkExpiresNotice(int hours) {
    return 'Este link expira em ${hours}h.';
  }

  @override
  String get searchByIdOrEmail => 'Buscar por ID ou e-mail';

  @override
  String get createLink => 'Criar link';

  @override
  String get noSearchResults => 'Nenhum resultado encontrado';

  @override
  String get createFirstFromDashboard =>
      'Crie seu primeiro Data Room a partir do painel';

  @override
  String get deleteDocumentTitle => 'Excluir documento';

  @override
  String get deleteDocumentWarning =>
      'Esta ação é irreversível. O documento será excluído permanentemente.';

  @override
  String get linkRevoked => 'Link revogado';

  @override
  String get documentDeleted => 'Documento excluído';

  @override
  String shareMessageTemplate(String url, String appUrl, int hours) {
    return 'Documento seguro via KRIPTONSHARE\n\n$url\n\nSe o link não abrir o app, use:\n$appUrl\n\nEste link expira em ${hours}h.';
  }

  @override
  String hoursRemaining(int hours) {
    return '${hours}h restantes';
  }

  @override
  String daysRemaining(int days) {
    return '${days}d restantes';
  }

  @override
  String viewsCount(int count) {
    return '$count visualizações';
  }

  @override
  String get activeTag => 'ATIVO';

  @override
  String get expiredTag => 'EXPIRADO';

  @override
  String expiresOn(String date) {
    return 'Expira: $date';
  }

  @override
  String get expiredLinksTitle => 'Links expirados';

  @override
  String get noExpiredLinks => 'Sem links expirados';

  @override
  String get allDataRoomsActive => 'Todos os seus Data Rooms estão ativos';

  @override
  String sizeExpiredOn(String size, String date) {
    return '$size · Expirou em $date';
  }

  @override
  String get linkIdMissing => 'ID do link não fornecido';

  @override
  String get linkInvalidExpiredRevoked => 'Link inválido, expirado ou revogado';

  @override
  String recipientOnlyNotice(String recipient) {
    return 'Este arquivo foi enviado para $recipient. Faça login com essa conta para acessá-lo.';
  }

  @override
  String documentLoadError(String error) {
    return 'Erro ao carregar o documento: $error';
  }

  @override
  String get invalidDecryptedFile =>
      'O arquivo descriptografado não é válido. Verifique a senha.';

  @override
  String get incompleteFileData =>
      'Dados do arquivo incompletos ou corrompidos.';

  @override
  String get wrongPasswordOrCorrupt => 'Senha incorreta ou arquivo corrompido';

  @override
  String get secureDocument => 'Documento seguro';

  @override
  String get encryptedFileReceived => 'Você recebeu um arquivo criptografado';

  @override
  String get senderPasswordPrompt =>
      'Digite a senha fornecida pelo remetente para descriptografá-lo';

  @override
  String get decryptionPasswordLabel => 'Senha de descriptografia';

  @override
  String get decryptAndView => 'Descriptografar e visualizar';

  @override
  String get selfDestructNotice =>
      'Este documento se autodestrói após a expiração. Não é armazenado no seu dispositivo.';

  @override
  String get decryptingDocument => 'Descriptografando documento...';

  @override
  String get unexpectedError => 'Erro inesperado';

  @override
  String pdfOpenError(String error) {
    return 'Não foi possível abrir o PDF:\n$error';
  }

  @override
  String get pdfViewerFallback =>
      'O visualizador nativo não pôde exibir este PDF. Por segurança, não é permitido abri-lo fora do app.';

  @override
  String get decryptedVideo => 'Vídeo descriptografado';

  @override
  String get playVideo => 'Reproduzir vídeo';

  @override
  String get protectedFormat => 'Formato protegido';

  @override
  String get officeNotViewable =>
      'Documentos do Microsoft Office e outros formatos não podem ser visualizados diretamente no app por segurança.';

  @override
  String get convertToPdfAdvice =>
      'Para compartilhar este conteúdo com segurança, converta-o para PDF antes de enviá-lo.';

  @override
  String get confidentialBanner => 'KRIPTONSHARE | CONFIDENCIAL';

  @override
  String get secureMode => 'MODO SEGURO';

  @override
  String get backToHome => 'Voltar ao início';

  @override
  String get unknownError => 'Erro desconhecido';

  @override
  String videoPlaybackError(String error) {
    return 'Não foi possível reproduzir o vídeo: $error';
  }

  @override
  String fileSizeAndType(String size, String mimeType) {
    return '$size · $mimeType';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get yourCurrentPlan => 'Seu plano atual';

  @override
  String get maxFileSize => 'Tamanho máximo por arquivo';

  @override
  String get dataRoomStorage => 'Armazenamento do Data Room';

  @override
  String get notAvailable => 'Não disponível';

  @override
  String get monthlyLinks => 'Links mensais';

  @override
  String get maxDuration => 'Duração máxima';

  @override
  String hoursValue(int count) {
    return '$count horas';
  }

  @override
  String daysValue(int count) {
    return '$count dias';
  }

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get encryptionLabel => 'Criptografia';

  @override
  String get watermarkLabel => 'Marca d\'água';

  @override
  String get institutionalPassiveWatermark => 'Institucional passiva';

  @override
  String get biometricsLabel => 'Biometria';

  @override
  String get configureBiometrics => 'Configure digital ou Face ID';

  @override
  String get unlockFullCapacity => 'Desbloqueie a capacidade total';

  @override
  String get premiumBenefits =>
      '100 MB por arquivo • links ilimitados • até 30 dias • 1 GB de armazenamento efêmero • marca d’água dinâmica';

  @override
  String get managePremiumVault => 'Gerenciar Vault Premium';

  @override
  String get analyticsTitle => 'Análises';

  @override
  String get noDataAvailable => 'Não há dados disponíveis';

  @override
  String get dataRoomsMetrics => 'Métricas dos seus Data Rooms';

  @override
  String get topLinks => 'Principais links';

  @override
  String get linkEvents => 'Eventos do link';

  @override
  String get viewExpiredLinks => 'Ver links expirados';

  @override
  String get totalLinks => 'Links totais';

  @override
  String get activeLabel => 'Ativos';

  @override
  String get expiredLabel => 'Expirados';

  @override
  String get totalViews => 'Visualizações totais';

  @override
  String get downloadsLabel => 'Downloads';

  @override
  String get avgDuration => 'Duração média';

  @override
  String get events24h => 'Eventos 24h';

  @override
  String get storageLabel => 'Armazenamento';

  @override
  String get noActivityYet => 'Sem atividade ainda';

  @override
  String get topLinksEmptyHint => 'Seus links mais vistos aparecerão aqui';

  @override
  String get unnamedDocument => 'Documento sem nome';

  @override
  String viewsDownloadsSummary(int views, int downloads) {
    return '$views visualizações · $downloads downloads';
  }

  @override
  String get noEventsForLink => 'Não há eventos registrados para este link';

  @override
  String pageN(int number) {
    return 'Página $number';
  }

  @override
  String get eventPageView => 'Visualização de página';

  @override
  String get eventDownloadComplete => 'Download concluído';

  @override
  String get eventDownloadStart => 'Início do download';

  @override
  String get eventScreenshotBlocked => 'Captura de tela bloqueada';

  @override
  String aes256Encrypted(String size) {
    return '$size · Criptografado AES-256';
  }

  @override
  String confidentialUserWatermark(String email) {
    return '$email • CONFIDENCIAL';
  }

  @override
  String get premiumActive => 'PREMIUM ATIVO';

  @override
  String get freePlanBadge => 'PLANO GRATUITO';

  @override
  String storageUsedOf(String used, String max) {
    return '$used / $max Usados';
  }

  @override
  String get subscriptionOptions => 'Opções de Assinatura';

  @override
  String get monthlyPlan => 'Mensal';

  @override
  String get monthlyPrice => 'US\$ 19,00 / mês';

  @override
  String get annualPlan => 'Anual';

  @override
  String get annualPrice => 'US\$ 189,00 / ano';

  @override
  String get annualSavings => 'Economize US\$ 39/ano';

  @override
  String get subscribeToPremium => 'Assinar o Premium';

  @override
  String get restorePurchases => 'Restaurar Compras';

  @override
  String get testModeLabel => 'MODO DE TESTE (debug)';

  @override
  String get testModeDescription =>
      'Ative o Premium sem RevenueCat nem Google Cloud para avaliar a interface.';

  @override
  String get deactivateTestPremium => 'Desativar Premium de teste';

  @override
  String get activateTestPremium => 'Ativar Premium de teste';

  @override
  String get testPremiumActivated => 'Premium de teste ativado';

  @override
  String get testPremiumDeactivated => 'Premium de teste desativado';

  @override
  String get noOfferingsAvailable => 'Não há ofertas disponíveis';

  @override
  String get subscriptionActivated => 'Assinatura ativada';

  @override
  String remainingLinks(int remaining) {
    return '$remaining restantes';
  }

  @override
  String get freePlanLabel => 'Plano gratuito';

  @override
  String get premiumPlanLabel => 'Plano Premium';

  @override
  String get errorUserNotAuthenticated => 'Usuário não autenticado';

  @override
  String get errorQuotaExceeded => 'Limite de cotas excedido';

  @override
  String get errorUploadNotAllowed =>
      'Não foi possível concluir o upload. Verifique os limites do seu plano.';

  @override
  String get errorSignInFailed => 'Não foi possível fazer login';

  @override
  String get errorUserRecordMissing =>
      'Usuário autenticado não encontrado na tabela users.';

  @override
  String get errorCreateRoomFailed => 'Não foi possível criar o Data Room';

  @override
  String get errorInvalidLinkFragment => 'Link inválido: fragmento ausente';

  @override
  String get errorInvalidKey => 'Chave inválida';

  @override
  String get errorDecryptionFailed => 'Erro ao descriptografar';

  @override
  String errorDecryptionWithDetail(String error) {
    return 'Erro ao descriptografar: $error';
  }

  @override
  String get uploadFileMax => 'Enviar arquivo (≤ 100 MB)';

  @override
  String get sendAction => 'Enviar';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByLastModified => 'Última modificação';

  @override
  String get sortBySize => 'Tamanho';

  @override
  String get gridView => 'Visualização em grade';

  @override
  String get listView => 'Visualização em lista';

  @override
  String linkExpiresInLabel(int days) {
    return 'Link expira em: $days dias';
  }

  @override
  String get recipientEmailRequiredTitle =>
      'Digite seu e-mail para acessar os documentos';

  @override
  String get dataRoomAccessAuditNotice =>
      'Digite seu e-mail para continuar. O acesso será auditado.';

  @override
  String get accessAction => 'Acessar';

  @override
  String get encryptedAtOrigin => 'Criptografado na origem';

  @override
  String get shareSingleFile => 'Arquivo individual';

  @override
  String get requireRecipientEmailLabel => 'E-mail do destinatário obrigatório';

  @override
  String get requireRecipientEmailSubtitle =>
      'O destinatário deverá digitar seu e-mail antes de acessar';

  @override
  String get enableWatermarkLabel => 'Marca d\'água dinâmica';

  @override
  String get enableWatermarkSubtitle =>
      'Sobrepõe e-mail, IP e data do destinatário no documento';

  @override
  String get expirationPremiumNotice =>
      'Premium: os links podem durar até 30 dias';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get shareQrCode => 'Compartilhar código QR';

  @override
  String get errorExpirationMustBeFuture =>
      'A data de expiração deve ser futura.';

  @override
  String get errorExpirationPremiumMax =>
      'Premium: a expiração máxima de um link é de 30 dias.';

  @override
  String get errorExpirationFreemiumMax =>
      'Plano gratuito: a expiração máxima de um link é de 48 horas.';

  @override
  String get expirationPremiumValid => 'Expiração Premium válida (≤ 30 dias).';

  @override
  String get expirationFreemiumValid => 'Expiração gratuita válida (≤ 48 h).';

  @override
  String get unlockPremiumTitle => 'Desbloqueie o Premium';

  @override
  String get paywallBody =>
      'Envie arquivos maiores, crie links ilimitados e mantenha seus arquivos por mais tempo.';

  @override
  String get close => 'Fechar';

  @override
  String get popular => 'POPULAR';

  @override
  String get premiumPlanName => 'Premium';

  @override
  String get businessPlanName => 'Business';

  @override
  String get monthlyLabel => 'Mensal';

  @override
  String get yearlyLabel => 'Anual';

  @override
  String yearlySaveLabel(int percent) {
    return 'Economize $percent%';
  }

  @override
  String get subscribeToBusiness => 'Assinar o Business';

  @override
  String get trialBannerTitle => 'Comece seu teste grátis';

  @override
  String get trialBannerBody =>
      'Experimente o Premium grátis por 14 dias. Cancele quando quiser.';

  @override
  String featureFileSize(int size) {
    return 'Até $size MB por arquivo';
  }

  @override
  String featureStorage(String storage) {
    return '$storage de armazenamento';
  }

  @override
  String featureLinkDuration(int days) {
    return 'Links de até $days dias';
  }

  @override
  String featureActiveLinks(int count) {
    return 'Até $count links ativos';
  }

  @override
  String get featureActiveLinksUnlimited => 'Links ativos ilimitados';

  @override
  String get featureNoAds => 'Sem anúncios';

  @override
  String get unsupportedFormatTitle => 'Formato não suportado';

  @override
  String unsupportedFormatBody(String formats) {
    return 'Por segurança, o KRIPTONSHARE só aceita arquivos nestes formatos: $formats. Converta seu documento para PDF antes de compartilhá-lo.';
  }

  @override
  String unsupportedViewerBody(String formats) {
    return 'Este formato não pode ser visualizado com segurança dentro do app. Formatos aceitos: $formats.';
  }

  @override
  String get plansTitle => 'Planos e armazenamento';

  @override
  String trialBanner(int days) {
    return 'Experimente o Premium: $days dias restantes';
  }

  @override
  String get trialPromo =>
      '14 dias de Premium grátis. Sem necessidade de cartão.';

  @override
  String get trialExpiredTitle => 'Sua avaliação do Premium terminou';

  @override
  String get trialExpiredBody =>
      'Você voltou ao plano grátis: 20 MB por arquivo, 20 links por mês e expiração em 7 dias. Mantenha 100 MB, links ilimitados e 30 dias com o Premium.';

  @override
  String get businessBenefits =>
      '200 MB por arquivo • 5 GB no total • links de até 60 dias • tudo do Premium • suporte prioritário • marca própria no visualizador (em breve)';

  @override
  String get premiumPriceMonthly => '\$12.99/mês';

  @override
  String get premiumPriceAnnual => '\$103.99/ano';

  @override
  String get premiumAnnualSavings => '4 meses grátis (economia de 33%)';

  @override
  String get businessPriceMonthly => '\$29.99/mês';

  @override
  String get businessPriceAnnual => '\$239.99/ano';

  @override
  String get businessAnnualSavings => 'Economize 33%';

  @override
  String get paywallFileSizeTitle => 'Arquivo grande demais';

  @override
  String paywallFileSizeBody(String maxSize) {
    return 'Seu plano permite $maxSize por arquivo. Com o Premium você pode compartilhar até 100 MB.';
  }

  @override
  String get paywallActiveLinksTitle => 'Limite de links ativos';

  @override
  String get paywallActiveLinksBody =>
      'O plano grátis permite 3 links ativos por vez. Com o Premium eles são ilimitados.';

  @override
  String get paywallMonthlyQuotaTitle => 'Limite mensal atingido';

  @override
  String get paywallMonthlyQuotaBody =>
      'Você criou 20 links neste mês. Com o Premium eles são ilimitados.';

  @override
  String get paywallDurationTitle => 'Duração máxima do plano grátis';

  @override
  String get paywallDurationBody =>
      'Links grátis duram até 7 dias. Com o Premium, até 30.';

  @override
  String get paywallStorageTitle => 'Armazenamento cheio';

  @override
  String paywallStorageBody(String quota) {
    return 'Você usou $quota de armazenamento. Exclua links ativos para liberar espaço ou faça upgrade do seu plano.';
  }

  @override
  String get paywallStorageBodyBusiness =>
      'Você usou os 5 GB completos. Exclua ou expire links ativos para liberar espaço.';

  @override
  String get paywallViewPlans => 'Ver planos';

  @override
  String get paywallNotNow => 'Agora não';

  @override
  String get max7Days => '7 dias (máx.)';

  @override
  String get max60Days => '60 dias (máx.)';

  @override
  String get ephemeralStorageLabel => 'Armazenamento efêmero total';

  @override
  String get businessBadge => 'BUSINESS';

  @override
  String get businessPlanLabel => 'Plano Business';
}
