// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'FriendsRide';

  @override
  String get driverMode => 'Mod Șofer';

  @override
  String get passengerMode => 'Mod Pasager';

  @override
  String get requestRide => 'Solicită Cursă';

  @override
  String get acceptRide => 'Acceptă';

  @override
  String get declineRide => 'Refuză';

  @override
  String get cancelRide => 'Anulează Cursa';

  @override
  String get myLocation => 'Locația mea';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get available => 'Disponibil';

  @override
  String get unavailable => 'Indisponibil';

  @override
  String get activeRide => 'Cursă Activă';

  @override
  String get rideHistory => 'Istoric Curse';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Setări';

  @override
  String get startNavigation => 'Navigarea a început';

  @override
  String get navigationEnded => 'Navigarea s-a încheiat';

  @override
  String get arrived => 'Ați ajuns la destinație';

  @override
  String get routeDeviation => 'Recalculez traseul';

  @override
  String get preparingRoute => 'Pregătesc traseul';

  @override
  String turnLeft(String distance) {
    return 'Virați la stânga peste $distance';
  }

  @override
  String turnRight(String distance) {
    return 'Virați la dreapta peste $distance';
  }

  @override
  String turnSlightLeft(String distance) {
    return 'Virați ușor la stânga peste $distance';
  }

  @override
  String turnSlightRight(String distance) {
    return 'Virați ușor la dreapta peste $distance';
  }

  @override
  String continueForward(String distance) {
    return 'Continuați înainte pentru $distance';
  }

  @override
  String makeUturn(String distance) {
    return 'Faceți întoarcere peste $distance';
  }

  @override
  String get meters => 'metri';

  @override
  String get kilometers => 'kilometri';

  @override
  String get meter => 'metru';

  @override
  String get kilometer => 'kilometru';

  @override
  String get driverHeadingToYou => 'Șoferul este pe drum...';

  @override
  String get driverArrived => 'Șoferul a sosit!';

  @override
  String get rideInProgress => 'Cursă în desfășurare';

  @override
  String get confirmDriver => 'Confirmă Șoferul';

  @override
  String get confirmButton => 'Confirmă';

  @override
  String get declineButton => 'Refuză';

  @override
  String get iArrived => 'Am ajuns';

  @override
  String get startRide => 'Pornește cursa';

  @override
  String get endRide => 'Termină Cursa';

  @override
  String get waitingForPassenger => 'Așteaptă pasagerul.';

  @override
  String get headingToPassenger => 'Mergi spre pasager.';

  @override
  String get communicateWithDriver => 'Comunică cu șoferul:';

  @override
  String get call => 'Sună';

  @override
  String get message => 'Mesaj';

  @override
  String get chat => 'Chat';

  @override
  String get writeMessage => 'Scrie un mesaj...';

  @override
  String get send => 'Trimite';

  @override
  String get emergency => 'Urgență';

  @override
  String get navigationTo => 'Navighează spre';

  @override
  String get navigation => 'Navigație';

  @override
  String get chooseNavigationApp => 'Alege aplicația de navigație';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get waze => 'Waze';

  @override
  String get locationNotAvailable =>
      'Locația nu este încă disponibilă pentru partajare.';

  @override
  String get shareLocation => 'Partajează Locația';

  @override
  String get navigateToPassenger => 'Navighează spre pasager';

  @override
  String get navigateToDestination => 'Navighează spre destinație';

  @override
  String get rideCompleted => 'Cursă finalizată';

  @override
  String get rideCancelled => 'Cursă anulată';

  @override
  String get rideExpired => 'Cursă expirată';

  @override
  String get offlineDriverMessage =>
      'Ești indisponibil ca șofer. Activează comutatorul pentru a primi curse sau solicită o cursă ca pasager.';

  @override
  String get noPendingRides => 'Nicio cerere de cursă disponibilă momentan.';

  @override
  String rideToDestination(String destination) {
    return 'Către: $destination';
  }

  @override
  String get cost => 'Cost';

  @override
  String distance(String km) {
    return 'Distanță ($km km):';
  }

  @override
  String get ron => 'RON';

  @override
  String get km => 'km';

  @override
  String get language => 'Limba';

  @override
  String get romanian => 'Română';

  @override
  String get english => 'English';

  @override
  String get errorInitializingRide => 'Eroare la inițializarea cursei';

  @override
  String get errorMonitoringRide => 'Eroare la monitorizarea cursei';

  @override
  String get cannotOpenNavigation =>
      'Nu s-a putut deschide nicio aplicație de navigație.';

  @override
  String get cannotMakeCall => 'Nu s-a putut iniția apelul.';

  @override
  String get joinTeamTitle => 'Alătură-te echipei FriendsRide!';

  @override
  String get joinTeamDescription =>
      'Devino șofer partener. Află mai multe aici.';

  @override
  String get youHaveActiveRide =>
      'Ai o cursă activă. Atinge pentru a vedea detaliile.';

  @override
  String get categoryStandardSubtitle =>
      'Cea mai accesibilă opțiune pentru călătoriile tale.';

  @override
  String get categoryFamilySubtitle =>
      'Mai mult spațiu pentru pasageri și bagaje.';

  @override
  String get categoryEnergySubtitle =>
      'Călătorește eco-friendly cu vehicule electrice sau hibride.';

  @override
  String get categoryBestSubtitle =>
      'Experiență premium cu vehicule de lux și șoferi de top.';

  @override
  String get aiAssistant => 'Asistent AI';

  @override
  String get voiceSettings => 'Setări Vocale';

  @override
  String get voiceDemo => 'Demo Voce AI';

  @override
  String get microphoneTest => 'Test Microfon';

  @override
  String get aiLibraryTest => 'Test Biblioteca AI';

  @override
  String get receipts => 'Chitante';

  @override
  String get driverDashboard => 'Panou de Bord Șofer';

  @override
  String get scheduleRide => 'Rezervă o cursă';

  @override
  String get subscriptions => 'Abonamente';

  @override
  String get safety => 'Siguranță';

  @override
  String get help => 'Ajutor';

  @override
  String get aiVoiceSettings => '🎤 Setări Vocale AI';

  @override
  String get voiceAIDemo => '🗣️ Demo Voice AI';

  @override
  String get microphoneTestTool => '🔧 Test Microfon';

  @override
  String get aiLibraryTestTool => '🧠 Test Biblioteca AI';

  @override
  String get about => 'Despre';

  @override
  String get legal => 'Juridic';

  @override
  String get logout => 'DECONECTARE';

  @override
  String get aboutFriendsRide => 'Despre FriendsRide';

  @override
  String get evaluateApp => 'Evaluează Aplicația';

  @override
  String get howManyStars => 'Câte stele dai aplicației FriendsRide?';

  @override
  String get starSelected => 'stea selectată';

  @override
  String get starsSelected => 'stele selectate';

  @override
  String get cancel => 'Anulează';

  @override
  String get select => 'Selectează';

  @override
  String ratingSentSuccessfully(String rating) {
    return '✅ Rating de $rating stele trimis cu succes!';
  }

  @override
  String get career => 'Carieră';

  @override
  String get joinOurTeam => 'Alătură-te echipei noastre';

  @override
  String get evaluateApplication => 'Evaluează aplicația';

  @override
  String get giveStarRating => '⭐ Dă un rating cu stele';

  @override
  String get followUs => 'Urmărește-ne';

  @override
  String get legalInformation => 'Informații Juridice';

  @override
  String get termsConditions => 'Termeni & Condiții';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsConditionsTitle =>
      'Termeni și Condiții pentru Rezervări și Anulări';

  @override
  String get generalProvisions => 'Prevederi Generale';

  @override
  String get generalProvisionsText =>
      'Anularea unei curse după alocarea unui șofer partener poate atrage o taxă de anulare pentru a compensa timpul și distanța parcursă de către șofer. Anularea este gratuită oricând înainte de alocarea unui șofer partener.';

  @override
  String get standardWaitTime => 'Timp de Așteptare Standard';

  @override
  String get standardWaitTimeText =>
      'După sosirea la locația de preluare, șoferul partener va aștepta gratuit timp de 5 minute. După expirarea acestui interval, se pot aplica taxe suplimentare de așteptare sau cursa poate fi anulată, aplicându-se taxa de anulare corespunzătoare.';

  @override
  String get specificCategoryPolicies => 'Politici Specifice pe Categorii';

  @override
  String get cancellationFee => 'Taxă de Anulare:';

  @override
  String get freeCancellation => 'Anulare Gratuită (Curse Rezervate):';

  @override
  String get minimumBookingTime => 'Timp Minim de Rezervare:';

  @override
  String get friendsRideStandard => 'FriendsRide Standard';

  @override
  String get friendsRideEnergy => 'FriendsRide Energy';

  @override
  String get friendsRideBest => 'FriendsRide Best';

  @override
  String get friendsRideFamily => 'FriendsRide Family';

  @override
  String get standardCancellationFee => '30 RON';

  @override
  String get energyCancellationFee => '30 RON';

  @override
  String get bestCancellationFee => '30 RON';

  @override
  String get familyCancellationFee => '30 RON';

  @override
  String get standardFreeCancellation =>
      'Cu cel puțin 1 oră și 30 de minute înainte de ora programată.';

  @override
  String get standardMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get energyMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get bestMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get familyMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get privacyPolicyContent =>
      'Aici va fi afișat conținutul detaliat al Politicii de Confidențialitate, conform normelor GDPR. Documentul va explica ce tipuri de date personale sunt colectate (nume, email, locație, date de plată, etc.), scopul colectării (funcționarea serviciului, marketing, siguranță), cum sunt stocate și protejate datele, perioada de retenție, și care sunt drepturile utilizatorilor (dreptul la acces, rectificare, ștergere, etc.).\n\nTextul complet va fi furnizat de un consultant juridic pentru a asigura conformitatea cu legislația în vigoare.';

  @override
  String get wallet => 'Portofel';

  @override
  String get currentBalance => 'Balanță Curentă';

  @override
  String get paymentMethods => 'Metode de Plată';

  @override
  String get addOrManageCards => 'Adaugă sau gestionează cardurile';

  @override
  String get cash => 'Numerar';

  @override
  String get selectPaymentMethod => 'Selectează Metoda de Plată';

  @override
  String get vouchers => 'Vouchere';

  @override
  String get addPromoCode => 'Adaugă un cod promoțional';

  @override
  String get transactionHistory => 'Istoric Tranzacții';

  @override
  String get viewAllPayments => 'Vezi toate plățile și încasările';

  @override
  String get canSendToContact => 'Poți trimite unei persoane de contact';

  @override
  String get addPaymentMethod => 'Adaugă o metodă de plată';

  @override
  String get rideProfiles => 'Profilurile curselor';

  @override
  String get startUsing => 'Începe să folosești';

  @override
  String get friendsRideForBusiness => 'FriendsRide for Business';

  @override
  String get activateBusinessFeatures =>
      'Activează funcțiile pentru călătorii în interes de serviciu';

  @override
  String get manageBusinessTrips =>
      'Gestionează curse în interes de serviciu pe...';

  @override
  String get requestBusinessProfileAccess =>
      'Solicită accesul la profilul Business';

  @override
  String get addVoucherCode => 'Adaugă codul voucherului';

  @override
  String get promotions => 'Promoţii';

  @override
  String get recommendations => 'Recomandări';

  @override
  String get addReferralCode => 'Adaugă codul de recomandare';

  @override
  String get inStoreOffers => 'Oferte în magazin';

  @override
  String get offers => 'Oferte';

  @override
  String get walletDetails => 'Detalii Portofel';

  @override
  String get walletDetailsInfo =>
      'FriendsRide Cash este balanța ta digitală. Poți adăuga fonduri pentru plăți mai rapide.';

  @override
  String get addFunds => 'Adaugă Fonduri';

  @override
  String get addFundsComingSoon =>
      'Funcționalitatea de adăugare fonduri va fi disponibilă în curând.';

  @override
  String get paymentMethodDetails => 'Detalii Metodă de Plată';

  @override
  String get brand => 'Brand';

  @override
  String get last4Digits => 'Ultimele 4 cifre';

  @override
  String get cardholder => 'Titular card';

  @override
  String get expiryDate => 'Data expirării';

  @override
  String get cashPaymentMethod => 'Plata se face direct șoferului în numerar.';

  @override
  String get delete => 'Șterge';

  @override
  String get deletePaymentMethodComingSoon =>
      'Funcționalitatea de ștergere metodă de plată va fi disponibilă în curând.';

  @override
  String get businessProfile => 'Profil Business';

  @override
  String get businessProfileInfo =>
      'Activează profilul Business pentru a gestiona curse în interes de serviciu.';

  @override
  String get businessProfileBenefits => 'Beneficii:';

  @override
  String get businessProfileBenefit1 => 'Rapoarte detaliate pentru cheltuieli';

  @override
  String get businessProfileBenefit2 => 'Facturare automată către companie';

  @override
  String get businessProfileBenefit3 => 'Gestionare multiple utilizatori';

  @override
  String get requestAccess => 'Solicită Acces';

  @override
  String get businessProfileRequestSent =>
      'Cererea pentru profil Business a fost trimisă. Vei primi un răspuns în curând.';

  @override
  String get referralCodeInfo =>
      'Introdu codul de recomandare pentru a primi beneficii.';

  @override
  String get enterReferralCode => 'Introdu codul';

  @override
  String get referralCodeApplied =>
      'Codul de recomandare a fost aplicat cu succes!';

  @override
  String get personalProfileActive => 'Profilul Personal este activ.';

  @override
  String get inStoreOffersComingSoon =>
      'Ofertele în magazin vor fi disponibile în curând.';

  @override
  String get close => 'Închide';

  @override
  String get paymentMethodDeleted =>
      'Metoda de plată a fost ștearsă cu succes.';

  @override
  String get errorDeletingPaymentMethod =>
      'Eroare la ștergerea metodei de plată.';

  @override
  String get errorRequestingBusinessProfile =>
      'Eroare la trimiterea cererii pentru profil business.';

  @override
  String get errorApplyingReferralCode =>
      'Eroare la aplicarea codului de recomandare.';

  @override
  String get paymentMethodsHelpTitle => 'Metode de Plată';

  @override
  String get addingPaymentMethod => 'Adăugarea unei metode de plată:';

  @override
  String get goToWalletSection =>
      '• Accesează secțiunea \"Portofel\" din meniul principal';

  @override
  String get tapAddPaymentMethod =>
      '• Apasă pe butonul \"Adaugă o metodă de plată\"';

  @override
  String get selectCardOrCash =>
      '• Selectează tipul de metodă (card sau numerar)';

  @override
  String get enterCardDetails =>
      '• Completează detaliile cardului (număr, dată expirare, CVV)';

  @override
  String get savePaymentMethod => '• Salvează metoda de plată';

  @override
  String get managingPaymentMethods => 'Gestionarea metodelor de plată:';

  @override
  String get viewAllMethodsInWallet =>
      '• Vezi toate metodele salvate în secțiunea \"Portofel\"';

  @override
  String get editOrDeleteMethods => '• Editează sau șterge metodele existente';

  @override
  String get setDefaultPaymentMethod =>
      '• Setează o metodă ca implicită pentru plăți automate';

  @override
  String get paymentMethodsTypes => 'Tipuri de metode de plată:';

  @override
  String get creditDebitCards => '• Carduri de credit/debit (Visa, Mastercard)';

  @override
  String get cashPayment => '• Numerar (plata se face direct șoferului)';

  @override
  String get walletBalance => '• FriendsRide Cash (balanță în portofel)';

  @override
  String get paymentSecurity => 'Securitate plăți:';

  @override
  String get allPaymentsSecure => '• Toate plățile sunt procesate în siguranță';

  @override
  String get cardDetailsEncrypted =>
      '• Detaliile cardurilor sunt criptate și stocate securizat';

  @override
  String get pciCompliant =>
      '• Aplicația respectă standardele PCI DSS pentru securitate';

  @override
  String get paymentMethodTip => '💡 Sfat util:';

  @override
  String get youCanSendToContact =>
      'Poți trimite bani către persoane de contact folosind metodele de plată salvate.';

  @override
  String get vouchersHelpTitle => 'Vouchere';

  @override
  String get addingVoucher => 'Adăugarea unui voucher:';

  @override
  String get tapVouchersSection =>
      '• Apasă pe secțiunea \"Vouchere\" din Portofel';

  @override
  String get tapAddVoucherCode => '• Apasă pe \"Adaugă codul voucherului\"';

  @override
  String get enterVoucherCode => '• Introdu codul voucherului';

  @override
  String get applyVoucher => '• Apasă \"Aplică\" pentru a activa voucherul';

  @override
  String get usingVouchers => 'Utilizarea voucherelor:';

  @override
  String get vouchersAppliedAutomatically =>
      '• Voucherele se aplică automat la următoarea cursă';

  @override
  String get checkVoucherStatus =>
      '• Verifică statusul voucherelor în secțiunea Vouchere';

  @override
  String get voucherExpiryInfo => '• Voucherele au o dată de expirare';

  @override
  String get voucherTypes => 'Tipuri de vouchere:';

  @override
  String get percentageDiscount => '• Reducere procentuală (ex: 10% reducere)';

  @override
  String get fixedAmountDiscount => '• Reducere fixă (ex: 5 RON reducere)';

  @override
  String get freeRideVoucher => '• Cursă gratuită';

  @override
  String get voucherTip => '💡 Sfat util:';

  @override
  String get oneVoucherPerRide => 'Poți folosi un singur voucher per cursă.';

  @override
  String get walletHelpTitle => 'Portofel';

  @override
  String get walletOverview => 'Prezentare generală:';

  @override
  String get walletOverviewInfo =>
      'Secțiunea Portofel îți permite să gestionezi metodele de plată, voucherele, și balanța FriendsRide Cash.';

  @override
  String get friendsRideCash => 'FriendsRide Cash:';

  @override
  String get friendsRideCashInfo => '• Balanță digitală pentru plăți rapide';

  @override
  String get addFundsToWallet => '• Poți adăuga fonduri în portofel';

  @override
  String get useWalletForPayments =>
      '• Poți folosi balanța pentru plăți automate';

  @override
  String get walletSections => 'Secțiuni disponibile:';

  @override
  String get paymentMethodsSection =>
      '• Metode de plată - gestionează cardurile și numerarul';

  @override
  String get vouchersSection =>
      '• Vouchere - adaugă și gestionează coduri promoționale';

  @override
  String get rideProfilesSection =>
      '• Profilurile curselor - Personal și Business';

  @override
  String get promotionsSection =>
      '• Promoții - coduri promoționale și recomandări';

  @override
  String get walletTip => '💡 Sfat util:';

  @override
  String get walletBalanceNeverExpires =>
      'Balanța FriendsRide Cash nu expiră niciodată.';

  @override
  String get earningsToday => 'Câștiguri Astăzi';

  @override
  String get ridesToday => 'Curse Astăzi';

  @override
  String get averageRating => 'Rating Mediu';

  @override
  String get lastCompletedRides => 'Ultimele Curse Finalizate';

  @override
  String get allRides => 'Toate Cursele';

  @override
  String get todayRides => 'Cursele de Astăzi';

  @override
  String get generateDailyReport => 'Generează Raport Zilnic';

  @override
  String get noRidesYet => 'Nicio cursă finalizată încă';

  @override
  String get viewDetails => 'Vezi Detalii';

  @override
  String get addTrustedContact => 'Adaugă contact de încredere';

  @override
  String get name => 'Nume';

  @override
  String get phoneNumber => 'Număr de telefon';

  @override
  String get phoneNumberExample => 'ex: 0712 345 678';

  @override
  String get save => 'Salvează';

  @override
  String contactSaved(String name) {
    return 'Contactul $name a fost salvat.';
  }

  @override
  String get trustedContacts => 'Contacte de încredere';

  @override
  String get noContacts => 'Niciun contact de încredere adăugat încă';

  @override
  String get emergencyCall => 'Apel de Urgență';

  @override
  String get safetyFeatures => 'Funcții de Siguranță';

  @override
  String get emergencyAssistance => 'Asistență de Urgență';

  @override
  String get shareTrip => 'Partajează Cursa';

  @override
  String get reportIncident => 'Raportează Incident';

  @override
  String get helpCenter => 'Centru de Ajutor';

  @override
  String get frequentlyAskedQuestions => 'Întrebări Frecvente';

  @override
  String get contactSupport => 'Contactează Suportul';

  @override
  String get reportProblem => 'Raportează o problemă';

  @override
  String get cannotRequestRide => 'Nu pot solicita o cursă';

  @override
  String get cannotRequestRideContent =>
      'Dacă întâmpinați probleme la solicitarea unei curse, încercați următoarele soluții:';

  @override
  String get checkInternetConnection => '2. Verificați conexiunea la internet';

  @override
  String get ensureGpsEnabled => '• Asigurați-vă că locația GPS este activată';

  @override
  String get restartApp => '1. Restartați aplicația';

  @override
  String get checkValidPayment =>
      '• Verificați dacă aveți o metodă de plată validă';

  @override
  String get contactSupportIfPersists =>
      '• Contactați echipa de suport dacă problema persistă';

  @override
  String get pickupTimeLonger =>
      'Timpul de preluare este mai mare decât cel estimat';

  @override
  String get pickupTimeLongerContent =>
      'Timpul estimat poate varia din următoarele motive:';

  @override
  String get unexpectedHeavyTraffic => '• Trafic intens neașteptat';

  @override
  String get unfavorableWeather => '• Condiții meteorologice nefavorabile';

  @override
  String get driverFindingAddress =>
      '• Șoferul poate avea dificultăți în găsirea adresei';

  @override
  String get specialEvents => '• Evenimente speciale în zona dvs.';

  @override
  String get contactDriverDirectly =>
      'Puteți contacta șoferul direct prin aplicație pentru a clarifica situația.';

  @override
  String get rideDidNotHappen => 'Cursa nu a avut loc';

  @override
  String get rideDidNotHappenContent => 'Dacă cursa nu a avut loc, verificați:';

  @override
  String get rideStatusInApp => '• Statusul cursei în aplicație';

  @override
  String get messagesFromDriver => '• Mesajele de la șofer';

  @override
  String get correctLocation => '• Dacă ați fost la locația corectă';

  @override
  String get contactSupportForRefund =>
      'Pentru rambursări, contactați suportul cu detaliile cursei.';

  @override
  String get lostItems => 'Obiecte pierdute';

  @override
  String get lostItemsContent => 'Dacă ați uitat ceva în mașina șoferului:';

  @override
  String get contactDriverImmediately =>
      '1. Contactați imediat șoferul prin aplicație';

  @override
  String get describeLostItem => '2. Descrieți obiectul pierdut';

  @override
  String get arrangePickup => '3. Stabiliți o întâlnire pentru recuperare';

  @override
  String get reportToSupport =>
      '4. Dacă nu reușiți să contactați șoferul, raportați prin suport';

  @override
  String get returnFeeNote =>
      'Notă: Poate fi aplicată o taxă mică pentru returnarea obiectelor.';

  @override
  String get driverDeviatedRoute => 'Șoferul a deviat de la traseu';

  @override
  String get driverDeviatedContent => 'Dacă șoferul a luat o rută diferită:';

  @override
  String get askDriverReason => '• Întrebați șoferul despre motivul schimbării';

  @override
  String get checkTrafficWorks =>
      '• Verificați dacă există trafic sau lucrări pe traseul inițial';

  @override
  String get reportIfUnjustified =>
      '• Dacă considerați că devierea este nejustificată, raportați';

  @override
  String get driversCanChooseAlternatives =>
      'Șoferii pot alege rute alternative pentru a evita traficul.';

  @override
  String get emergencyAssistanceUsage => 'Utilizarea asistenței de urgență';

  @override
  String get emergencyAssistanceContent => 'Funcția de urgență vă permite să:';

  @override
  String get quickCall112 => '• Apelați rapid 112';

  @override
  String get sendLocationToContact =>
      '• Trimiteți locația dvs. unui contact de urgență';

  @override
  String get reportIncidentToSafety =>
      '• Raportați un incident către echipa de siguranță';

  @override
  String get voiceSettingsSaved => 'Setările vocale au fost salvate';

  @override
  String get availableVoiceCommands => 'Comenzi Vocale Disponibile';

  @override
  String get basicCommands => 'Comenzi de bază:';

  @override
  String get wantRideToDestination => '\"Vreau o cursă la [destinație]\"';

  @override
  String get economyRideToDestination => '\"Cursă economică la [destinație]\"';

  @override
  String get urgentRideToDestination => '\"Cursă urgentă la [destinație]\"';

  @override
  String get premiumRideToDestination => '\"Cursă premium la [destinație]\"';

  @override
  String get commandsDuringRide => 'Comenzi în timpul cursei:';

  @override
  String get sendMessageToDriver => '\"Trimite mesaj șoferului\"';

  @override
  String get whereIsDriver => '\"Unde este șoferul?\"';

  @override
  String get wantToPayCash => '\"Vreau să plătesc cash\"';

  @override
  String get controlCommands => 'Comenzi de control:';

  @override
  String get heyFriendsRide => '\"Hey FriendsRide\" (activare)';

  @override
  String get helpCommand => '\"Ajutor\" (ajutor)';

  @override
  String get cancelCommand => '\"Anulează\" (anulare)';

  @override
  String get stopCommand => '\"Stop\" (oprire)';

  @override
  String get advancedHelp => 'Ajutor Avansat';

  @override
  String get advancedFeaturesAvailable => 'Funcții avansate disponibile:';

  @override
  String get automaticVoiceActivation => '   - Activare vocală automată';

  @override
  String get customActivationWord => '   - Personalizare cuvânt activare';

  @override
  String get realtimeDetection => '   - Detectare în timp real';

  @override
  String get continuousListening => 'Ascultare continuă';

  @override
  String get continuousListeningForCommands =>
      '   - Ascultare continuă pentru comenzi';

  @override
  String get realtimeProcessing => '   - Procesare în timp real';

  @override
  String get smartBatterySaving => '   - Economie baterie inteligentă';

  @override
  String get multiLanguageSupport => 'Suport multi-limbă';

  @override
  String get supportFor6Languages => '   - Suport pentru 6 limbi';

  @override
  String get voiceSwitchBetweenLanguages => '   - Comutare vocală între limbi';

  @override
  String get localAccentAdaptation => '   - Adaptare accent local';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get localProcessing => '   - Procesare locală';

  @override
  String get endToEndEncryption => '   - Criptare end-to-end';

  @override
  String get fullDataControl => '   - Control total asupra datelor';

  @override
  String get contactSupportForTechnical =>
      'Pentru asistență tehnică, contactați suportul.';

  @override
  String get listening => 'Vă Ascult';

  @override
  String get sayYourAnswer => 'Spuneți răspunsul:';

  @override
  String get acceptOrDecline => '\"ACCEPT\" sau \"REFUZ\"';

  @override
  String get greeting => 'Salutare! Unde doriți să mergeți?';

  @override
  String get account => 'Cont';

  @override
  String get personalInformation => 'Informații Personale';

  @override
  String get changePassword => 'Schimbă Parola';

  @override
  String get security => 'Securitate';

  @override
  String get notifications => 'Notificări';

  @override
  String get reportGenerated => 'Raport Generat';

  @override
  String get dailyReportGeneratedSuccess =>
      'Raportul zilnic a fost generat cu succes. Doriți să vă întoarceți la harta principală?';

  @override
  String get stayHere => 'Rămân aici';

  @override
  String get goToMap => 'Mergi la Hartă';

  @override
  String get driverOptions => 'Opțiuni Șofer';

  @override
  String get generatingReport => 'Generez raport...';

  @override
  String get showAll => 'Arată Toate';

  @override
  String get noRidesMatchFilter =>
      'Nu există nicio cursă care să corespundă filtrului.';

  @override
  String get to => 'Către:';

  @override
  String get destination => 'Destinație';

  @override
  String get driverModeDeactivated => 'Modul Șofer Dezactivat';

  @override
  String get goToMapAndActivate =>
      'Mergi la Hartă și activează switch-ul pentru a primi curse.';

  @override
  String get youAreAvailable => 'Ești Disponibil pentru Curse';

  @override
  String get newRidesWillAppear =>
      'Cursele noi vor apărea pe hartă ca notificări interactive.';

  @override
  String get waitingForPassengerConfirmation =>
      'Aștepți confirmarea pasagerului';

  @override
  String get confirmedGoToPassenger => 'Confirmată - Mergi spre pasager';

  @override
  String get earningsTodayShort => 'Câștiguri Azi';

  @override
  String get completedRidesToday => 'Curse finalizate azi';

  @override
  String get ridesTodayShort => 'Curse Azi';

  @override
  String get averageRatingShort => 'Rating Mediu';

  @override
  String errorGeneratingReport(String error) {
    return 'Eroare la generarea raportului: $error';
  }

  @override
  String get noRidesTodayForReport =>
      'Nu există curse finalizate astăzi pentru raport.';

  @override
  String get safetyCenter => 'Centrul de Siguranță';

  @override
  String get addContact => 'Adaugă contact';

  @override
  String get emergencyAssistanceButton => 'Butonul de Asistență de Urgență';

  @override
  String get emergencyAssistanceButtonDesc =>
      'În timpul oricărei curse, aveți la dispoziție butonul 112 în colțul ecranului pentru a contacta rapid serviciile de urgență.';

  @override
  String get tripSharing => 'Partajarea Traseului';

  @override
  String get tripSharingDesc =>
      'Puteți partaja detaliile cursei și traseul în timp real cu prietenii sau familia pentru un plus de siguranță.';

  @override
  String get verifiedDrivers => 'Șoferi Verificați';

  @override
  String get verifiedDriversDesc =>
      'Toți șoferii parteneri trec printr-un proces riguros de verificare a documentelor și a istoricului pentru a asigura siguranța dumneavoastră.';

  @override
  String get reportIncidentTitle => 'Raportarea unui Incident';

  @override
  String get reportIncidentDesc =>
      'Dacă întâmpinați orice problemă de siguranță, o puteți raporta direct din aplicație, din secțiunea Ajutor, iar echipa noastră va investiga prompt.';

  @override
  String get noTrustedContactsYet =>
      'Nu ați adăugat încă persoane de încredere.';

  @override
  String get addFamilyFriends =>
      'Adăugați rapid familia sau prietenii care vor primi notificări atunci când partajați o cursă.';

  @override
  String get sendTestMessage => 'Trimite mesaj de test';

  @override
  String contactRemoved(String name) {
    return 'Contactul $name a fost eliminat.';
  }

  @override
  String get couldNotOpenMessages =>
      'Nu am putut deschide aplicația de mesaje pentru acest contact.';

  @override
  String get testMessageBody =>
      'Te-am setat ca persoană de încredere în FriendsRide. Voi partaja călătoriile active când am nevoie de ajutor.';

  @override
  String get voiceSystemActive => 'Sistemul vocal este activ';

  @override
  String get voiceSystemNotActive => 'Sistemul vocal nu este activ';

  @override
  String get canUseVoiceCommands =>
      'Puteți folosi comenzi vocale pentru a rezerva curse';

  @override
  String get checkMicrophonePermissions =>
      'Verificați permisiunile pentru microfon';

  @override
  String get activate => 'Activează';

  @override
  String get basicMode => 'Basic Mode';

  @override
  String get continuous => 'Continuous';

  @override
  String get on => 'ON';

  @override
  String get off => 'OFF';

  @override
  String get generalSettings => 'Setări Generale';

  @override
  String get continuousListeningSubtitle =>
      'Ascultă continuu pentru comenzi vocale';

  @override
  String get voicePreferences => 'Preferințe Vocale';

  @override
  String get speechRate => 'Viteza de vorbire';

  @override
  String percentOfNormalSpeed(int percent) {
    return '$percent% din viteza normală';
  }

  @override
  String get volume => 'Volumul';

  @override
  String percentOfMaxVolume(int percent) {
    return '$percent% din volumul maxim';
  }

  @override
  String get pitch => 'Tonul';

  @override
  String get lowerPitch => 'Ton mai jos';

  @override
  String get normalPitch => 'Ton normal';

  @override
  String get higherPitch => 'Ton mai înalt';

  @override
  String get german => 'Deutsch';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';

  @override
  String get italian => 'Italiano';

  @override
  String get advancedVoiceFeatures => 'Funcții Vocale Avansate';

  @override
  String get voiceCommandTraining => 'Antrenare comenzi vocale';

  @override
  String get voiceCommandTrainingSubtitle =>
      'Îmbunătățește recunoașterea comenzilor';

  @override
  String get customVoiceProfile => 'Profil vocal personalizat';

  @override
  String get customVoiceProfileSubtitle => 'Adaptează sistemul la vocea dvs';

  @override
  String get multiLanguageSupportSubtitle =>
      'Comutați între limbi în timpul conversației';

  @override
  String get advancedSettings => 'Setări Avansate';

  @override
  String get testMicrophone => 'Testează microfonul';

  @override
  String get testMicrophoneSubtitle =>
      'Verifică dacă microfonul funcționează corect';

  @override
  String get testSound => 'Testează sunetul';

  @override
  String get testSoundSubtitle => 'Verifică dacă sunetul funcționează corect';

  @override
  String get testRecognition => 'Testează recunoașterea';

  @override
  String get testRecognitionSubtitle => 'Verifică recunoașterea vocală';

  @override
  String get voiceCommandsHelp => 'Ajutor comenzi vocale';

  @override
  String get voiceCommandsHelpSubtitle =>
      'Lista completă de comenzi disponibile';

  @override
  String get privacySettings => 'Confidențialitate';

  @override
  String get privacySettingsSubtitle =>
      'Gestionați datele vocale și confidențialitatea';

  @override
  String get analyticsAndImprovements => 'Analiză și îmbunătățiri';

  @override
  String get analyticsAndImprovementsSubtitle =>
      'Gestionați analiza vocală pentru îmbunătățiri';

  @override
  String get saveSettings => 'Salvează Setările';

  @override
  String get voiceSystemActivatedSuccessfully =>
      'Sistemul vocal a fost activat cu succes!';

  @override
  String errorActivatingVoiceSystem(String error) {
    return 'Eroare la activarea sistemului vocal: $error';
  }

  @override
  String get activateVoiceSystemFirst => 'Activează mai întâi sistemul vocal.';

  @override
  String errorTestingMicrophone(String error) {
    return 'Eroare la testarea microfonului: $error';
  }

  @override
  String errorTestingSound(String error) {
    return 'Eroare la testarea sunetului: $error';
  }

  @override
  String errorTestingRecognition(String error) {
    return 'Eroare la testarea recunoașterii: $error';
  }

  @override
  String get voiceCommandTrainingTitle => 'Antrenare Comenzi Vocale';

  @override
  String get voiceCommandTrainingContent =>
      'Antrenarea va îmbunătăți recunoașterea comenzilor vocale. Vă va fi cerut să repetați comenzi multiple ori pentru a crea un profil vocal personalizat.';

  @override
  String get later => 'Mai târziu';

  @override
  String get startTraining => 'Începe Antrenarea';

  @override
  String get trainingStepsTitle => 'Pași Antrenare';

  @override
  String get repeatCommand1 => '1. Repetați comanda \"Vreau o cursă\" de 3 ori';

  @override
  String get repeatCommand2 =>
      '2. Repetați comanda \"Cursă economică\" de 3 ori';

  @override
  String get repeatCommand3 =>
      '3. Repetați comanda \"Anulează cursă\" de 3 ori';

  @override
  String get repeatCommand4 => '4. Repetați comanda \"Ajutor\" de 3 ori';

  @override
  String get trainingWillTakeApprox =>
      'Antrenarea va dura aproximativ 5 minute.';

  @override
  String get customVoiceProfileTitle => 'Profil Vocal Personalizat';

  @override
  String get customVoiceProfileContent =>
      'Creați un profil vocal personalizat pentru a îmbunătăți recunoașterea. Sistemul va învăța să vă recunoască vocea și să se adapteze la accentul dvs.';

  @override
  String get createProfile => 'Creează Profil';

  @override
  String get multiLanguageSettingsTitle => 'Suport Multi-limbă';

  @override
  String get primaryLanguage => 'Limba principală: Română';

  @override
  String get secondaryLanguages => 'Limbi secundare:';

  @override
  String get switchBetweenLanguages =>
      'Puteți comuta între limbi spunând \"Switch to English\" sau \"Schimbă în română\"';

  @override
  String get availableVoiceCommandsTitle => 'Comenzi Vocale Disponibile';

  @override
  String get privacySettingsTitle => 'Confidențialitate Vocală';

  @override
  String get privacySettingsLabel => 'Setări confidențialitate:';

  @override
  String get saveVoiceHistory => 'Salvează istoricul vocal';

  @override
  String get saveVoiceHistorySubtitle =>
      'Stochează comenzile vocale pentru îmbunătățirea serviciului';

  @override
  String get anonymousAnalysis => 'Analiză anonimă';

  @override
  String get anonymousAnalysisSubtitle =>
      'Permite analiza anonimă pentru îmbunătățirea recunoașterii';

  @override
  String get cloudSync => 'Sincronizare cloud';

  @override
  String get cloudSyncSubtitle =>
      'Sincronizează preferințele vocale între dispozitive';

  @override
  String get voiceDataProcessedLocally =>
      'Datele vocale sunt procesate local pe dispozitivul dvs pentru confidențialitate maximă.';

  @override
  String get analyticsSettingsTitle => 'Analiză și Îmbunătățiri';

  @override
  String get analyticsSettingsLabel => 'Setări analiză:';

  @override
  String get improveRecognition => 'Îmbunătățire recunoaștere';

  @override
  String get improveRecognitionSubtitle =>
      'Permite analiza pentru îmbunătățirea recunoașterii vocale';

  @override
  String get usageStatistics => 'Statistici utilizare';

  @override
  String get usageStatisticsSubtitle =>
      'Colectează statistici despre utilizarea funcțiilor vocale';

  @override
  String get errorReporting => 'Raportare erori';

  @override
  String get errorReportingSubtitle =>
      'Raportează automat erorile vocale pentru rezolvare';

  @override
  String get allDataAnonymized =>
      'Toate datele sunt anonimizate și nu conțin informații personale.';

  @override
  String get advancedHelpTitle => 'Ajutor Avansat';

  @override
  String get aiSpeaking => '🗣️ AI VORBEȘTE\n\nVă rog ascultați...';

  @override
  String get aiListening => '🎤 AI ASCULTĂ\n\nVORBIȚI ACUM!';

  @override
  String get aiProcessing => '🧠 AI PROCESEAZĂ\n\nVă rog așteptați...';

  @override
  String get waitingForResponse => 'AȘTEPT RĂSPUNS';

  @override
  String get voiceAssistant => 'ASISTENT VOCAL';

  @override
  String get pleaseListenToResponse => 'Vă rog ascultați răspunsul...';

  @override
  String get speakNow => 'VORBIȚI ACUM!';

  @override
  String get processingInformation => 'Procesez informația...';

  @override
  String get pleaseWait => 'Vă rog așteptați...';

  @override
  String get pressButtonToStart => 'Apăsați butonul pentru a începe';

  @override
  String get newRideAudioUnavailable => 'CURSĂ NOUĂ! (Audio indisponibil)';

  @override
  String get emergencyAssistanceUsageContent =>
      'Funcția de urgență vă permite să:';

  @override
  String get call112Quickly => '• Apelați rapid 112';

  @override
  String get sendLocationToEmergencyContact =>
      '• Trimiteți locația dvs. unui contact de urgență';

  @override
  String get reportIncidentToSafetyTeam =>
      '• Raportați un incident către echipa de siguranță';

  @override
  String get useOnlyRealEmergencies =>
      'Utilizați această funcție doar în situații reale de urgență.';

  @override
  String get reportAccidentOrUnpleasantEvent =>
      'Raportează accident sau eveniment neplăcut';

  @override
  String get toReportIncident => 'Pentru a raporta un incident:';

  @override
  String get ensureYourSafety => '1. Asigurați-vă de siguranța dvs';

  @override
  String get useEmergencyFunctionInApp =>
      '2. Folosiți funcția de urgență din aplicație';

  @override
  String get describeInDetail => '3. Descrieți detaliat ce s-a întâmplat';

  @override
  String get addPhotosIfPossible => '4. Adăugați fotografii dacă este posibil';

  @override
  String get cooperateWithInvestigationTeam =>
      '5. Cooperați cu echipa de investigații';

  @override
  String get falseReportsCanLead =>
      'Raporturile false pot duce la suspendarea contului.';

  @override
  String get cleaningOrDamageFee => 'Taxă curățenie sau daune';

  @override
  String get cleaningFeeTitle =>
      '🧹 Taxa pentru curățenie și daune în aplicația FriendsRide';

  @override
  String get cleaningFeeIntro =>
      'La FriendsRide, ne dorim ca toate călătoriile să fie plăcute și confortabile pentru toți utilizatorii noștri. Din acest motiv, avem o politică clară privind curățenia vehiculelor și responsabilitatea pentru eventualele daune.';

  @override
  String get whenFeeApplied =>
      '🚨 Când se aplică taxa pentru curățenie sau daune?';

  @override
  String get spillingLiquids =>
      '1. Vărsarea de lichide în vehicul (apă, cafea, sucuri, alcool, etc.)';

  @override
  String get soilingSeatsOrFloor =>
      '2. Murdărirea scaunelor sau podelei cu noroi, mâncare sau alte substanțe';

  @override
  String get vomitingInVehicle => '3. Vărsături în vehicul';

  @override
  String get smokingInVehicle =>
      '4. Fumatul în vehicul (inclusiv țigări electronice)';

  @override
  String get damagingVehicleElements =>
      '5. Deteriorarea unor elemente din vehicul (scaune, centuri, etc.)';

  @override
  String get leavingFoodOrTrash =>
      '6. Lăsarea de resturi de mâncare sau gunoi în vehicul';

  @override
  String get persistentOdors =>
      '7. Mirosuri persistente care necesită dezodorizare profesională';

  @override
  String get howFeeProcessWorks =>
      '⚙️ Cum funcționează procesul de aplicare a taxei?';

  @override
  String get driverDocumentsDamage =>
      '1. Șoferul documentează paguba prin fotografii imediat după cursă';

  @override
  String get driverReportsIncident =>
      '2. Șoferul raportează incidentul prin aplicația FriendsRide în maxim 24 de ore';

  @override
  String get teamAnalyzesReport =>
      '3. Echipa noastră analizează raportul și fotografiile';

  @override
  String get ifFeeJustified =>
      '4. În cazul în care taxa este justificată, pasagerul va fi notificat';

  @override
  String get feeChargedAutomatically =>
      '5. Taxa va fi prelevată automat din metoda de plată asociată contului';

  @override
  String get passengerCanContest =>
      '6. Pasagerul poate contesta taxa în termen de 48 de ore de la notificare';

  @override
  String get feeAmounts => '💰 Cuantumul taxelor';

  @override
  String get lightCleaning => '🧽 Curățenie ușoară: 50-100 RON';

  @override
  String get wipingAndVacuuming =>
      '• Ștergerea și aspirarea urmelor ușoare de murdărie';

  @override
  String get removingSmallStains => '• Îndepărtarea petelor mici de pe scaune';

  @override
  String get intensiveCleaning => '🧼 Curățenie intensivă: 150-300 RON';

  @override
  String get professionalCleaning =>
      '• Curățare profesională pentru pete mari sau mirosuri';

  @override
  String get deodorizationAndSpecialTreatments =>
      '• Dezodorizare și tratamente speciale';

  @override
  String get repairsAndReplacements =>
      '🔧 Reparații și înlocuiri: 200-2000+ RON';

  @override
  String get replacingDamagedSeatCovers =>
      '• Înlocuirea hușelor de scaune deteriorate';

  @override
  String get repairingDamagedComponents =>
      '• Repararea componentelor deteriorate';

  @override
  String get costsDependOnSeverity =>
      '• Costurile depind de gravitatea daunelor';

  @override
  String get yourRightsAsPassenger => '⚖️ Drepturile dvs. ca pasager';

  @override
  String get rightToReceivePhotos =>
      '✅ Aveți dreptul să primiți fotografiile și detaliile complete ale daunelor';

  @override
  String get canContestFee =>
      '✅ Puteți contesta taxa în termen de 48 de ore prin aplicație';

  @override
  String get rightToObjectiveInvestigation =>
      '✅ Aveți dreptul la o investigație obiectivă a cazului dvs.';

  @override
  String get ifContestationJustified =>
      '✅ În cazul contestațiilor justificate, taxa va fi returnată integral';

  @override
  String get howToAvoidFee =>
      '🛡️ Cum să evitați taxa pentru curățenie sau daune';

  @override
  String get doNotConsumeFood =>
      '• Nu consumați mâncare sau băuturi în vehicul';

  @override
  String get checkShoesNotDirty =>
      '• Verificați că încălțămintea nu este murdară înainte de a urca';

  @override
  String get notifyDriverIfFeelingUnwell =>
      '• Anunțați șoferul dacă vă simțiți rău și aveți nevoie de o pauză';

  @override
  String get doNotSmokeInVehicle => '• Nu fumați în vehicul';

  @override
  String get treatVehicleWithRespect =>
      '• Tratați vehiculul cu același respect ca și cum ar fi al dvs.';

  @override
  String get takeTrashWithYou =>
      '• Duceți gunoiul cu dvs. la sfârșitul călătoriei';

  @override
  String get contestationProcess => '📝 Procesul de contestare';

  @override
  String get accessRideHistory =>
      '1. Accesați secțiunea \"Istoric călătorii\" din aplicație';

  @override
  String get selectRideForContestation =>
      '2. Selectați călătoria pentru care contestați taxa';

  @override
  String get pressContestFee =>
      '3. Apăsați pe \"Contestă taxa\" și completați formularul';

  @override
  String get addRelevantEvidence =>
      '4. Adăugați orice dovezi relevante (fotografii, explicații)';

  @override
  String get teamWillReanalyze =>
      '5. Echipa noastră va reanaliza cazul în maxim 72 de ore';

  @override
  String get receiveDetailedResponse =>
      '6. Veți primi un răspuns detaliat prin email și în aplicație';

  @override
  String get haveQuestionsOrNeedAssistance =>
      '📞 Aveți întrebări sau aveți nevoie de asistență?';

  @override
  String get emailSupport => '📧 Email: suport@friendsride.ro';

  @override
  String get phoneSupport => '📱 Telefon: +40 700 FRIENDS (373 637)';

  @override
  String get chatInApp => '💬 Chat în aplicație: Secțiunea \"Ajutor\"';

  @override
  String get scheduleSupport => '🕒 Program: Luni-Duminică, 24/7';

  @override
  String get importantToRemember => '⚠️ Important de reținut';

  @override
  String get feeOnlyAppliedWithClearEvidence =>
      'Taxa pentru curățenie și daune se aplică doar în cazurile în care există dovezi clare ale deteriorării sau murdăririi vehiculului. Echipa FriendsRide analizează fiecare caz individual și se asigură că toate taxele sunt justificate și corecte.';

  @override
  String get howToActivateDriverMode =>
      'Cum activez modul șofer partener Friends';

  @override
  String get toBecomeDriverPartner =>
      'Pentru a deveni șofer partener FriendsRide, urmează acești pași:';

  @override
  String get checkConditions => '1. Verifică condițiile';

  @override
  String get validLicenseRequired =>
      'Trebuie să ai permis de conducere valabil, experiență de minim 2 ani și vârsta de minim 21 de ani.';

  @override
  String get prepareDocuments => '2. Pregătește documentele';

  @override
  String get documentsNeeded =>
      'Ai nevoie de: permis de conducere, carte de identitate, certificat de înmatriculare auto, ITP valabil și asigurarea RCA.';

  @override
  String get completeApplication => '3. Completează aplicația';

  @override
  String get accessCareerSection =>
      'Accesează secțiunea \"Carieră\" din meniul principal și completează formularul online cu datele tale.';

  @override
  String get submitDocuments => '4. Transmite documentele';

  @override
  String get uploadClearPhotos =>
      'Încarcă fotografii clare cu toate documentele necesare prin platforma online.';

  @override
  String get applicationVerification => '5. Verificarea aplicației';

  @override
  String get teamWillVerify =>
      'Echipa noastră va verifica documentele în maxim 48 de ore lucrătoare.';

  @override
  String get receiveActivationCode => '6. Primește codul de activare';

  @override
  String get afterApproval =>
      'După aprobare, vei primi un cod unic prin email/SMS pentru activarea contului de șofer.';

  @override
  String get activateAccount => '7. Activează contul';

  @override
  String get enterCodeInApp =>
      'Introdu codul în aplicație și începe să câștigi bani conducând!';

  @override
  String get usefulTip => '💡 Sfat util:';

  @override
  String get ensureDocumentsValid =>
      'Asigură-te că toate documentele sunt valabile și fotografiile sunt clare pentru o procesare rapidă.';

  @override
  String get ratesAndPayments => 'Tarife și plăți';

  @override
  String get ratesAndPaymentsInfo => 'Informații despre Tarife și Plăți';

  @override
  String get ratesCalculatedAutomatically =>
      '• Tarifele sunt calculate automat în funcție de distanță și timp';

  @override
  String get paymentMadeAutomatically =>
      '• Plata se face automat prin metoda salvată în cont';

  @override
  String get canSeeRateDetails =>
      '• Puteți vedea detaliile tarifului înainte de a confirma cursa';

  @override
  String get inCaseOfPaymentProblems =>
      '• În caz de probleme cu plata, contactați suportul';

  @override
  String get forCurrentRatesDetails =>
      'Pentru detalii despre tarifele actuale, verificați în aplicație.';

  @override
  String get deliveryOrderRequest => 'Solicitare comandă livrare';

  @override
  String get deliveryServices => 'Servicii de Livrare';

  @override
  String get currentlyFocusedOnTransport =>
      'Momentan, ne concentrăm pe serviciile de transport persoane.';

  @override
  String get deliveryServicesAvailableSoon =>
      'Serviciile de livrare vor fi disponibile în viitorul apropiat.';

  @override
  String get weWillNotifyYou =>
      'Vă vom anunța când această funcție va fi activă!';

  @override
  String get appFunctioningProblems => 'Probleme de funcționare a aplicației';

  @override
  String get ifAppNotWorkingCorrectly =>
      'Dacă aplicația nu funcționează corect:';

  @override
  String get updateAppToLatest =>
      '3. Actualizați aplicația la cea mai recentă versiune';

  @override
  String get restartPhone => '4. Restartați telefonul';

  @override
  String get reinstallAppIfPersists =>
      '5. Reinstalați aplicația dacă problema persistă';

  @override
  String get ifProblemContinues =>
      'Dacă problema continuă, trimiteți-ne un raport prin suport.';

  @override
  String get forgotPassword => 'Am uitat parola';

  @override
  String get enterEmailAssociated =>
      'Introduceți adresa de email asociată contului dumneavoastră.';

  @override
  String get enterValidEmail => 'Introduceți o adresă de email validă.';

  @override
  String get sendingResetEmail => 'Se trimite emailul de resetare...';

  @override
  String get resetEmailSent =>
      'Un email de resetare a parolei a fost trimis. Verificați-vă inbox-ul (inclusiv folderul Spam)!';

  @override
  String get errorSendingResetEmail =>
      'A apărut o eroare la trimiterea email-ului de resetare.';

  @override
  String get noAccountWithEmail =>
      'Nu există niciun cont cu această adresă de email.';

  @override
  String get unexpectedError => 'A apărut o eroare neașteptată.';

  @override
  String get resetPassword => 'Resetare Parolă';

  @override
  String get applyNow => 'Aplică acum';

  @override
  String get contentComingSoon =>
      'Conținutul pentru acest subiect va fi disponibil în curând.';

  @override
  String get joinTeam => 'Alătură-te echipei Friends';

  @override
  String get applyForDriver => 'Aplică pentru Șofer partener Friends';

  @override
  String get activateDriverCode => 'Activare cod mod Șofer Friends';

  @override
  String get activateDriverCodeTitle => 'Activare Cod Șofer';

  @override
  String get activateDriverCodeDescription =>
      'Introduceți codul de activare primit pentru a deveni șofer partener Friends.';

  @override
  String get enterActivationCode => 'Vă rugăm introduceți codul de activare.';

  @override
  String get codeTooShort =>
      'Codul introdus este prea scurt. Verificați din nou.';

  @override
  String get validatingCode => 'Validez codul...';

  @override
  String get codeActivatedSuccess =>
      'Codul a fost activat cu succes! Acum sunteți șofer.';

  @override
  String get codeInvalidOrUsed =>
      'Cod invalid sau deja utilizat. Vă rugăm verificați.';

  @override
  String errorValidatingCode(String error) {
    return 'Eroare la validarea codului: $error';
  }

  @override
  String get lowDataMode => 'Mod date reduse';

  @override
  String get highContrastUI => 'Interfață contrast ridicat';

  @override
  String get assistantStatusOverlay => 'Suprapunere status asistent';

  @override
  String get performanceOverlay => 'Suprapunere performanță';

  @override
  String get aiGreeting => 'Salut, unde doriți să mergeți?';

  @override
  String get aiSearchingDrivers => 'Caut șoferi disponibili...';

  @override
  String get aiSearchingDriversInArea => 'Caut șoferi disponibili în zonă...';

  @override
  String aiDriverFound(int minutes) {
    return 'Am găsit un șofer disponibil la $minutes minute distanță.';
  }

  @override
  String get aiBestDriverSelected =>
      'Am selectat cel mai bun șofer pentru dumneavoastră. Trimit cererea de cursă...';

  @override
  String get aiNoDriversAvailable =>
      'Îmi pare rău, dar nu am găsit șoferi disponibili în zona dumneavoastră. Te rugăm să revii mai târziu.';

  @override
  String get aiEverythingResolved =>
      'Perfect! Am rezolvat totul automat. Cererea dvs. de cursă a fost trimisă!';

  @override
  String get subscriptionsTitle => 'Abonamente FriendsRide';

  @override
  String get recommended => 'RECOMANDAT';

  @override
  String get ronPerMonth => 'RON / lună';

  @override
  String planSelected(String plan) {
    return 'Ai selectat planul $plan! (simulare)';
  }

  @override
  String get choosePlan => 'Alege Planul';

  @override
  String get subscriptionBasicDescription => 'Pentru călătorii ocazionali.';

  @override
  String get subscriptionPlusDescription => 'Cel mai popular plan.';

  @override
  String get subscriptionPremiumDescription => 'Beneficii exclusive.';

  @override
  String get subscriptionBasicBenefit1 => '5% reducere la 10 curse/lună';

  @override
  String get subscriptionBasicBenefit2 => 'Anulare gratuită în 2 minute';

  @override
  String get subscriptionPlusBenefit1 => '10% reducere la toate cursele';

  @override
  String get subscriptionPlusBenefit2 => 'Anulare gratuită în 5 minute';

  @override
  String get subscriptionPlusBenefit3 => 'Suport prioritar 24/7';

  @override
  String get subscriptionPremiumBenefit1 => '15% reducere la toate cursele';

  @override
  String get subscriptionPremiumBenefit2 => 'Anulare gratuită oricând';

  @override
  String get subscriptionPremiumBenefit3 => 'Suport prioritar 24/7';

  @override
  String get subscriptionPremiumBenefit4 => 'Acces la mașini premium';

  @override
  String get deleteConfirmation => 'Confirmare Ștergere';

  @override
  String deleteRideConfirmation(String destination) {
    return 'Sunteți sigur că doriți să ștergeți definitiv cursa către \"$destination\" din istoricul dumneavoastră? Această acțiune este ireversibilă.';
  }

  @override
  String get rideDeletedSuccess => 'Cursa a fost ștearsă cu succes!';

  @override
  String errorLoadingRole(String error) {
    return 'Eroare la încărcarea rolului: $error';
  }

  @override
  String get errorGeneric => 'Eroare';

  @override
  String get errorLoadingData => 'Eroare la încărcarea datelor';

  @override
  String errorDetails(String error) {
    return 'Detalii: $error';
  }

  @override
  String get retry => 'Reîncearcă';

  @override
  String get noRidesInPeriod => 'Nu aveți nicio cursă în perioada selectată.';

  @override
  String get filterAll => 'Tot';

  @override
  String get filterLastMonth => 'Ultima Lună';

  @override
  String get filterLast3Months => 'Ultimele 3 Luni';

  @override
  String get filterThisYear => 'Anul Acesta';

  @override
  String rideDate(String date) {
    return 'Data: $date';
  }

  @override
  String get deleteRide => 'Șterge cursa';

  @override
  String get asDriver => 'Ca Șofer';

  @override
  String get asPassenger => 'Ca Pasager';

  @override
  String get errorLoadingUserRole =>
      'Eroare la încărcarea rolului utilizatorului.';

  @override
  String get receiptsTitle => 'Chitantele Tale';

  @override
  String get receiptsTitlePassenger => 'Chitante (Pasager)';

  @override
  String get errorLoadingReceipts => 'Eroare la încărcarea chitanțelor';

  @override
  String get noReceiptsInPeriod =>
      'Nu aveți nicio chitanță în această categorie pentru perioada selectată.';

  @override
  String deleteSelectedReceipts(int count) {
    return 'Șterge $count chitante selectate?';
  }

  @override
  String get deleteSelectedReceiptsWarning =>
      'Această acțiune va șterge permanent chitanțele selectate. Acțiunea nu poate fi anulată.';

  @override
  String receiptsDeletedSuccess(int count) {
    return 'Au fost șterse cu succes $count chitante.';
  }

  @override
  String receiptsDeletedPartial(int deleted, int error) {
    return 'Au fost șterse $deleted chitante. $error nu au putut fi șterse.';
  }

  @override
  String deleteAllReceipts(int count) {
    return 'Șterge toate chitanțele ($count)?';
  }

  @override
  String get deleteAllReceiptsWarning =>
      'Această acțiune va șterge permanent TOATE chitanțele din perioada selectată. Acțiunea nu poate fi anulată.';

  @override
  String allReceiptsDeleted(int count) {
    return 'Au fost șterse $count chitante.';
  }

  @override
  String get filterAllReceipts => 'Toate';

  @override
  String get generating => 'Generez...';

  @override
  String get monthlyReportPDF => 'Raport Lunar PDF';

  @override
  String selectedCount(int count) {
    return '$count selectate';
  }

  @override
  String get selectAll => 'Selectează tot';

  @override
  String get deselectAll => 'Deselectează tot';

  @override
  String get deleteSelected => 'Șterge selectate';

  @override
  String get deleteAll => 'Șterge toate';

  @override
  String get noRidesForReport =>
      'Nu există curse în ultima lună pentru a genera raportul.';

  @override
  String get returnToMapQuestion =>
      'Doriți să vă întoarceți la harta principală?';

  @override
  String rideTo(String destination) {
    return 'Cursă către: $destination';
  }

  @override
  String rideFrom(String date) {
    return 'Ride from $date';
  }

  @override
  String get from => 'De la:';

  @override
  String get earningsSummary => 'Sumar Câștiguri';

  @override
  String get totalRide => 'Total Cursă:';

  @override
  String get appCommission => 'Comision Aplicație:';

  @override
  String get yourEarnings => 'Câștigul Tău:';

  @override
  String get activeRideDetected => 'Cursă activă detectată';

  @override
  String get cancelPreviousRide => 'Anulează cursa precedentă';

  @override
  String get rideAcceptedWaiting =>
      'Cursă acceptată! Așteptăm confirmarea pasagerului...';

  @override
  String get driverProfileLoading =>
      'Profilul șofer se încarcă, încercați din nou...';

  @override
  String get searching => 'Se caută…';

  @override
  String get searchInThisArea => 'Caută în această zonă';

  @override
  String get declining => 'Refuz...';

  @override
  String get decline => 'Refuză';

  @override
  String get accepting => 'Accept...';

  @override
  String get accept => 'Acceptă';

  @override
  String get addAsStop => 'Adaugă ca oprire';

  @override
  String get pickupPointDeleted => 'Punctul de plecare a fost șters';

  @override
  String get destinationDeleted => 'Destinația a fost ștearsă';

  @override
  String get selectPickupAndDestination =>
      'Selectează punctul de plecare și destinația';

  @override
  String get rideSummary => 'Sumar Cursă';

  @override
  String get couldNotLoadRideDetails =>
      'Nu s-au putut încărca detaliile cursei';

  @override
  String get back => 'Înapoi';

  @override
  String get noTip => 'Fără bacșiș';

  @override
  String get routeNotLoaded => '🗺️ Nu s-a putut încărca traseul automat';

  @override
  String get rideCancelledSuccess => 'Cursa a fost anulată cu succes';

  @override
  String get forceCancelRide => 'Anulează Forțat Cursa';

  @override
  String get passengerAddedStop =>
      'Pasagerul a adăugat o nouă oprire. Ruta a fost recalculată.';

  @override
  String get stopAdded =>
      'Oprire adăugată! Traseul și costul au fost actualizate.';

  @override
  String errorAddingStop(String error) {
    return 'Eroare la adăugarea opririi: $error';
  }

  @override
  String get navigationWithGoogleMaps => 'Navigație cu Google Maps';

  @override
  String get navigationWithWaze => 'Navigație cu Waze';

  @override
  String get safetyTeamNotified =>
      'Am notificat echipa de siguranță. Suntem alături de tine.';

  @override
  String get sendViaApps => 'Trimite prin aplicații';

  @override
  String get noTrustedContacts => 'Nu aveți contacte de încredere';

  @override
  String get manageContacts => 'Gestionează contacte';

  @override
  String get iAmSafe => 'Sunt în siguranță';

  @override
  String get falseAlarm => 'Alarmă falsă';

  @override
  String get shareRoute => 'Partajează traseul';

  @override
  String get rideCancelledSuccessShort => 'Cursa a fost anulată cu succes';

  @override
  String get recenterMap => 'Recentrează harta';

  @override
  String get mapMovedTapToRecenter => 'Mișcat harta. Atinge pentru recentrare';

  @override
  String get entrySelected => 'Intrare selectată.';

  @override
  String get addStop => 'Adaugă Oprire';

  @override
  String navigationBanner(String type, String modifier, String distance) {
    return 'Banner navigație. $type $modifier. Distanță $distance metri.';
  }

  @override
  String entrySelectedWithLabel(String label) {
    return 'Intrare selectată: $label';
  }

  @override
  String get editMessage => 'Editează mesajul';

  @override
  String get passengerNotifiedArrived =>
      '✅ Pasagerul a fost notificat că ai ajuns!';

  @override
  String get cannotOpenPhoneApp => 'Nu se poate deschide aplicația de telefon';

  @override
  String errorLoadingRoute(String error) {
    return 'Eroare la încărcarea rutei: $error';
  }

  @override
  String rideCancelledReason(String reason) {
    return 'Cursa anulată: $reason';
  }

  @override
  String get selectCancellationReason => 'Selectează motivul anulării:';

  @override
  String get backButton => 'Înapoi';

  @override
  String get passengerNotResponding => 'Pasager nu răspunde';

  @override
  String get technicalProblem => 'Problemă tehnică';

  @override
  String get pickupRide => 'Preluare Cursă';

  @override
  String get loadingPassengerInfo => 'Se încarcă informațiile pasagerului...';

  @override
  String get pleaseValidateAddress =>
      'Te rugăm să validezi adresa sau să o selectezi de pe hartă.';

  @override
  String get editAddress => 'Editează Adresa';

  @override
  String get addNewAddress => 'Adaugă Adresă Nouă';

  @override
  String errorVoiceRecognition(String error) {
    return 'Eroare la recunoașterea vocală: $error';
  }

  @override
  String get updateAddress => 'Actualizează Adresa';

  @override
  String get saveAddress => 'Salvează Adresa';

  @override
  String get resetPasswordButton => 'Resetează Parola';

  @override
  String get pleaseFillAllFields =>
      'Vă rugăm completați corect toate câmpurile.';

  @override
  String get welcomeBack => '👋 Bun venit înapoi!';

  @override
  String get welcomeToFriendsRide => 'Bun venit în FriendsRide!';

  @override
  String get pleaseEnterValidEmail =>
      'Vă rugăm introduceți o adresă de email validă în câmpul de Email pentru resetare.';

  @override
  String get errorResettingPassword =>
      'A apărut o eroare neașteptată la resetarea parolei.';

  @override
  String get enterValidPhoneNumber => 'Introduceți un număr de telefon valid.';

  @override
  String get autoAuthCompleted => 'Autentificare automată finalizată';

  @override
  String errorAutoAuth(String error) {
    return 'Eroare autentificare automată: $error';
  }

  @override
  String get enterSmsCode => 'Introduceți codul SMS primit.';

  @override
  String get verifyAndAuthenticate => 'Verifică și autentifică';

  @override
  String get max5Stops => 'Poți adăuga maximum 5 opriri';

  @override
  String addressNotFound(String address) {
    return 'Nu s-a putut găsi adresa: $address';
  }

  @override
  String noCoordinatesForDestination(String error) {
    return 'Nu s-au găsit coordonate pentru destinație: $error';
  }

  @override
  String get fillBothAddresses => 'Completează ambele adrese pentru a continua';

  @override
  String get intermediateStopAdded => 'Oprire intermediară adăugată';

  @override
  String get home => 'Acasă';

  @override
  String get work => 'Serviciu';

  @override
  String get edit => 'Editează';

  @override
  String get recentDestinations => 'Destinații Recente';

  @override
  String get noFavoriteAddressAdded => 'Nicio adresă favorită adăugată.';

  @override
  String get addressUpdated => 'Adresa a fost actualizată!';

  @override
  String get addressSaved => 'Adresa a fost salvată!';

  @override
  String get pleaseSelectRating =>
      'Te rugăm selectează un rating înainte de a trimite.';

  @override
  String get ratingSentSuccess => 'Evaluare trimisă cu succes!';

  @override
  String errorSendingRating(String error) {
    return 'Eroare la trimiterea evaluării: $error';
  }

  @override
  String get rideDetailsCompleted => 'Detalii Cursă Finalizată';

  @override
  String get saveRating => 'Salvează Evaluarea';

  @override
  String errorConfirmingDriver(String error) {
    return 'Eroare la confirmarea șoferului: $error';
  }

  @override
  String errorDecliningDriver(String error) {
    return 'Eroare la refuzarea șoferului: $error';
  }

  @override
  String get backToMap => 'Înapoi la Hartă';

  @override
  String get currentLocation => 'Locația actuală';

  @override
  String get finalDestination => 'Destinație finală';

  @override
  String get accordingToSelection => 'Conform selecției';

  @override
  String get waitingResponse => '⏳ AȘTEPT RĂSPUNS...';

  @override
  String get waitingConfirmation => '❓ AȘTEPT CONFIRMARE\n\nSpuneți DA sau NU';

  @override
  String get arrivedNotifyPassenger => 'Am ajuns - Anunță pasagerul';

  @override
  String get passengerBoarding => 'Pasagerul se îmbarcă';

  @override
  String get route => 'Rută';

  @override
  String get preferencesSaved => 'Preferințele au fost salvate';

  @override
  String get pleaseSelectRatingBeforeSubmit =>
      'Vă rugăm selectați un rating înainte de a trimite.';

  @override
  String get errorSubmittingRating =>
      'Eroare la trimiterea evaluării. Încercați din nou.';

  @override
  String get thankYouForRide => 'Vă mulțumim pentru călătorie!';

  @override
  String get howWasExperience => 'Cum a fost experiența?';

  @override
  String get leaveCommentOptional => 'Lasă un comentariu (opțional)';

  @override
  String get thanksForRating => 'Mulțumim pentru evaluare!';

  @override
  String get ratePassenger => 'Evaluează Pasagerul';

  @override
  String get shortCharacterization =>
      'Scurtă caracterizare (ex: curat, a murdărit mașina)';

  @override
  String get addPrivateNoteAboutPassenger =>
      'Adaugă o notă privată despre pasager...';

  @override
  String get routeUpdated => 'Traseu Actualizat';

  @override
  String get passengerAddedNewStop =>
      'Pasagerul a adăugat o nouă oprire. Ruta a fost recalculată.';

  @override
  String get ok => 'OK';

  @override
  String get rideManagement => 'Gestionare Cursă';

  @override
  String get modifyDestination => 'Modifică Destinația';

  @override
  String get cannotModifyCompletedRide =>
      'Nu poți modifica destinația pentru o cursă finalizată sau anulată.';

  @override
  String get destinationUpdatedSuccessfully =>
      'Destinația a fost actualizată cu succes!';

  @override
  String errorUpdatingDestination(String error) {
    return 'Eroare la actualizarea destinației: $error';
  }

  @override
  String get changeFinalLocation => 'Schimbă locația finală';

  @override
  String get intermediateStop => 'Oprire intermediară';

  @override
  String get mayIncludeCancellationFee => 'Poate include taxă de anulare';

  @override
  String get viewReceipt => 'Vizualizează Chitanța';

  @override
  String get completeRideDetails => 'Detalii complete ale cursei';

  @override
  String get rateRide => 'Evaluează Cursa';

  @override
  String get provideDriverFeedback => 'Oferă feedback șoferului';

  @override
  String get communication => 'Comunicare';

  @override
  String get callDriver => 'Sună Șoferul';

  @override
  String chatWith(String name) {
    return 'Chat cu $name';
  }

  @override
  String get chatAvailableSoon => 'Chat-ul va fi disponibil în curând';

  @override
  String get costSummary => 'Sumar Cost';

  @override
  String get baseFare => 'Tarif de bază:';

  @override
  String time(String min) {
    return 'Timp ($min min):';
  }

  @override
  String get totalPaid => 'Total Plătit:';

  @override
  String get ratingGiven => 'Rating acordat:';

  @override
  String get noRatingGiven => 'Niciun rating acordat';

  @override
  String get optionalComments => 'Comentarii opționale...';

  @override
  String get howWasYourExperience => 'Cum a fost experiența ta?';

  @override
  String get routeNotLoadedAuto => '🗺️ Nu s-a putut încărca traseul automat';

  @override
  String get rideCancelledSuccessfully => 'Cursa a fost anulată cu succes.';

  @override
  String get stopAddedRouteUpdated =>
      'Oprire adăugată! Traseul și costul au fost actualizate.';

  @override
  String get writeNewText => 'Scrie noul text...';

  @override
  String get messageEditedSuccess => 'Mesajul a fost editat cu succes!';

  @override
  String errorEditingMessage(String error) {
    return 'Eroare la editarea mesajului: $error';
  }

  @override
  String errorCancelling(String error) {
    return 'Eroare la anulare: $error';
  }

  @override
  String get splitPayment => 'Împărțire Plată';

  @override
  String get splitPaymentDescription =>
      'Împărțește costul cursei cu alți pasageri';

  @override
  String get createSplitPayment => 'Creează Împărțire';

  @override
  String get splitPaymentCreated => 'Împărțirea a fost creată';

  @override
  String get shareLinkWithParticipants =>
      'Partajează link-ul cu participanții:';

  @override
  String get share => 'Partajează';

  @override
  String get splitWithHowMany => 'Cu câți să împărți?';

  @override
  String get selectNumberOfPeople => 'Selectează numărul de persoane';

  @override
  String get confirm => 'Confirmă';

  @override
  String get acceptSplitPayment => 'Acceptă Împărțirea';

  @override
  String get markAsPaid => 'Marchează ca Plătit';

  @override
  String get totalAmount => 'Total';

  @override
  String get perPerson => 'Per Persoană';

  @override
  String get participants => 'Participanți';

  @override
  String get participant => 'Participant';

  @override
  String get paid => 'Plătit';

  @override
  String get pending => 'În așteptare';

  @override
  String get accepted => 'Acceptat';

  @override
  String get completed => 'Finalizat';

  @override
  String get rejected => 'Respins';

  @override
  String get cancelled => 'Anulat';

  @override
  String errorCreatingSplitPayment(String error) {
    return 'Eroare la crearea împărțirii: $error';
  }

  @override
  String errorAcceptingSplitPayment(String error) {
    return 'Eroare la acceptarea împărțirii: $error';
  }

  @override
  String errorCompletingPayment(String error) {
    return 'Eroare la finalizarea plății: $error';
  }

  @override
  String get paymentCompleted => 'Plata a fost finalizată';

  @override
  String get promotionCode => 'Cod Promoțional';

  @override
  String get enterPromotionCode => 'Introdu codul promoțional';

  @override
  String get apply => 'Aplică';

  @override
  String get promotionAppliedSuccessfully =>
      'Cod promoțional aplicat cu succes';

  @override
  String get subscriptionsHelpTitle => 'Abonamente și Promoții';

  @override
  String get subscriptionsHelpOverview =>
      'Abonamentele FriendsRide vă oferă beneficii exclusive și reduceri la curse.';

  @override
  String get subscriptionsHelpPlans => 'Planuri Disponibile:';

  @override
  String get subscriptionsHelpBasic =>
      '• Friends Basic - 5% reducere la 10 curse/lună';

  @override
  String get subscriptionsHelpPlus =>
      '• Friends Plus - 10% reducere la toate cursele (Recomandat)';

  @override
  String get subscriptionsHelpPremium =>
      '• Friends Premium - 15% reducere + beneficii exclusive';

  @override
  String get subscriptionsHelpHowToSubscribe => 'Cum să vă abonați:';

  @override
  String get subscriptionsHelpGoToMenu => '1. Accesați meniul hamburger';

  @override
  String get subscriptionsHelpTapSubscriptions =>
      '2. Apăsați pe \'Abonamente și Promoții\'';

  @override
  String get subscriptionsHelpSelectPlan => '3. Selectați planul dorit';

  @override
  String get subscriptionsHelpCompletePayment => '4. Completați plata';

  @override
  String get subscriptionsHelpPromotions => 'Promoții Active:';

  @override
  String get subscriptionsHelpPromotionsInfo =>
      'Verificați secțiunea \'Promoții\' pentru oferte speciale și coduri promoționale disponibile.';

  @override
  String get subscriptionsHelpReferral => 'Program de Recomandare:';

  @override
  String get subscriptionsHelpReferralInfo =>
      'Partajați codul dvs. de recomandare și primiți beneficii pentru fiecare prieten care se înscrie.';

  @override
  String get splitPaymentHelpTitle => 'Split Payment - Împărțirea Costului';

  @override
  String get splitPaymentHelpOverview =>
      'Split Payment vă permite să împărțiți costul cursei cu alți pasageri.';

  @override
  String get splitPaymentHelpHowToCreate => 'Cum să creați Split Payment:';

  @override
  String get splitPaymentHelpAfterRide =>
      '1. După finalizarea cursei, apăsați pe \'Split Payment\'';

  @override
  String get splitPaymentHelpSelectPeople =>
      '2. Selectați numărul de persoane cu care împărțiți';

  @override
  String get splitPaymentHelpShareLink =>
      '3. Partajați linkul generat cu participanții';

  @override
  String get splitPaymentHelpParticipantsAccept =>
      '4. Participanții acceptă și plătesc partea lor';

  @override
  String get splitPaymentHelpHowToAccept => 'Cum să acceptați Split Payment:';

  @override
  String get splitPaymentHelpReceiveLink => '1. Primirea linkului de partajare';

  @override
  String get splitPaymentHelpTapAccept => '2. Apăsați pe \'Accept Split\'';

  @override
  String get splitPaymentHelpSelectPayment => '3. Selectați metoda de plată';

  @override
  String get splitPaymentHelpCompletePayment => '4. Completați plata';

  @override
  String get splitPaymentHelpNote =>
      'Notă: Split Payment este disponibil doar pentru curse finalizate.';

  @override
  String get rideSharingHelpTitle => 'Ride Sharing - Curse Partajate';

  @override
  String get rideSharingHelpOverview =>
      'Ride Sharing vă permite să partajați cursa cu alți pasageri care merg în aceeași direcție.';

  @override
  String get rideSharingHelpHowToEnable => 'Cum să activați Ride Sharing:';

  @override
  String get rideSharingHelpDuringRequest =>
      '1. În timpul solicitării cursei, activați opțiunea \'Ride Sharing\'';

  @override
  String get rideSharingHelpSystemMatches =>
      '2. Sistemul va căuta automat alți pasageri compatibili';

  @override
  String get rideSharingHelpIfMatchFound =>
      '3. Dacă se găsește un match, veți fi notificat';

  @override
  String get rideSharingHelpBenefits => 'Beneficii:';

  @override
  String get rideSharingHelpCostReduction =>
      '• Reducere semnificativă a costului cursei';

  @override
  String get rideSharingHelpEcoFriendly => '• Opțiune prietenoasă cu mediul';

  @override
  String get rideSharingHelpSocial => '• Oportunitate de a cunoaște oameni noi';

  @override
  String get rideSharingHelpNote =>
      'Notă: Ride Sharing este disponibil doar pentru anumite rute și în anumite zone.';

  @override
  String get modifyDestinationHelpTitle => 'Modificare Destinație';

  @override
  String get modifyDestinationHelpOverview =>
      'Puteți modifica destinația cursei în timpul cursei active.';

  @override
  String get modifyDestinationHelpHowToModify =>
      'Cum să modificați destinația:';

  @override
  String get modifyDestinationHelpDuringRide =>
      '1. În timpul cursei active, apăsați pe \'Gestionare Cursă\'';

  @override
  String get modifyDestinationHelpTapModify =>
      '2. Apăsați pe \'Modifică Destinația\'';

  @override
  String get modifyDestinationHelpSelectNew => '3. Selectați noua destinație';

  @override
  String get modifyDestinationHelpConfirm => '4. Confirmați modificarea';

  @override
  String get modifyDestinationHelpRouteRecalculated =>
      '5. Ruta și prețul vor fi recalculate automat';

  @override
  String get modifyDestinationHelpLimitations => 'Limitări:';

  @override
  String get modifyDestinationHelpCannotModifyCompleted =>
      '• Nu puteți modifica destinația pentru curse finalizate sau anulate';

  @override
  String get modifyDestinationHelpPriceMayChange =>
      '• Prețul poate varia în funcție de noua destinație';

  @override
  String get modifyDestinationHelpDriverNotified =>
      '• Șoferul va fi notificat automat despre modificare';

  @override
  String get lowDataModeHelpTitle => 'Mod Date Reduse';

  @override
  String get lowDataModeHelpOverview =>
      'Modul Date Reduse reduce consumul de date mobile optimizând funcționalitățile aplicației.';

  @override
  String get lowDataModeHelpHowToEnable => 'Cum să activați Mod Date Reduse:';

  @override
  String get lowDataModeHelpGoToMenu => '1. Accesați meniul hamburger';

  @override
  String get lowDataModeHelpTapToggle =>
      '2. Găsiți opțiunea \'Mod date reduse\'';

  @override
  String get lowDataModeHelpActivate => '3. Activați toggle-ul';

  @override
  String get lowDataModeHelpWhatItDoes => 'Ce face Mod Date Reduse:';

  @override
  String get lowDataModeHelpReducesImages =>
      '• Reduce calitatea imaginilor și cache-ul';

  @override
  String get lowDataModeHelpLimitsAnimations =>
      '• Limitează animațiile și efectele vizuale';

  @override
  String get lowDataModeHelpOptimizesMaps =>
      '• Optimizează încărcarea hărților';

  @override
  String get lowDataModeHelpReducesSync =>
      '• Reduce sincronizarea în timp real';

  @override
  String get lowDataModeHelpBenefits => 'Beneficii:';

  @override
  String get lowDataModeHelpSavesData => '• Economisește date mobile';

  @override
  String get lowDataModeHelpFasterLoading =>
      '• Încărcare mai rapidă pe conexiuni slabe';

  @override
  String get lowDataModeHelpBatteryLife => '• Îmbunătățește durata bateriei';

  @override
  String get lowDataModeHelpNote =>
      'Notă: Mod Date Reduse poate afecta calitatea anumitor funcții, dar aplicația rămâne complet funcțională.';

  @override
  String get highContrastUIHelpTitle => 'Interfață Contrast Ridicat';

  @override
  String get highContrastUIHelpOverview =>
      'Interfața cu Contrast Ridicat îmbunătățește vizibilitatea pentru utilizatorii cu deficiențe de vedere sau în condiții de lumină slabă.';

  @override
  String get highContrastUIHelpHowToEnable =>
      'Cum să activați Interfața cu Contrast Ridicat:';

  @override
  String get highContrastUIHelpGoToMenu => '1. Accesați meniul hamburger';

  @override
  String get highContrastUIHelpTapToggle =>
      '2. Găsiți opțiunea \'Interfață contrast ridicat\'';

  @override
  String get highContrastUIHelpActivate => '3. Activați toggle-ul';

  @override
  String get highContrastUIHelpWhatItDoes =>
      'Ce face Interfața cu Contrast Ridicat:';

  @override
  String get highContrastUIHelpIncreasesContrast =>
      '• Mărește contrastul între text și fundal';

  @override
  String get highContrastUIHelpBolderText =>
      '• Face textul mai bold și mai ușor de citit';

  @override
  String get highContrastUIHelpClearerIcons =>
      '• Face iconițele și butoanele mai vizibile';

  @override
  String get highContrastUIHelpBetterVisibility =>
      '• Îmbunătățește vizibilitatea în condiții de lumină slabă';

  @override
  String get highContrastUIHelpBenefits => 'Beneficii:';

  @override
  String get highContrastUIHelpAccessibility =>
      '• Îmbunătățește accesibilitatea pentru utilizatori cu deficiențe de vedere';

  @override
  String get highContrastUIHelpReadability => '• Text mai ușor de citit';

  @override
  String get highContrastUIHelpOutdoorUse =>
      '• Utilizare mai bună în condiții de lumină puternică';

  @override
  String get highContrastUIHelpNote =>
      'Notă: Interfața cu Contrast Ridicat este disponibilă atât pentru tema clară, cât și pentru tema întunecată.';

  @override
  String get assistantStatusOverlayHelpTitle => 'Suprapunere Status Asistent';

  @override
  String get assistantStatusOverlayHelpOverview =>
      'Suprapunerea Status Asistent afișează un indicator mic în colțul ecranului care arată când asistentul AI procesează comenzi.';

  @override
  String get assistantStatusOverlayHelpHowToEnable =>
      'Cum să activați Suprapunerea Status Asistent:';

  @override
  String get assistantStatusOverlayHelpGoToMenu =>
      '1. Accesați meniul hamburger';

  @override
  String get assistantStatusOverlayHelpTapToggle =>
      '2. Găsiți opțiunea \'Suprapunere status asistent\'';

  @override
  String get assistantStatusOverlayHelpActivate => '3. Activați toggle-ul';

  @override
  String get assistantStatusOverlayHelpWhatItShows =>
      'Ce afișează indicatorul:';

  @override
  String get assistantStatusOverlayHelpWorking =>
      '• \'Lucrez\' - când asistentul AI procesează comenzi sau interacționează cu utilizatorul';

  @override
  String get assistantStatusOverlayHelpWaiting =>
      '• \'Aștept comenzi\' - când asistentul AI este inactiv și așteaptă comenzi';

  @override
  String get assistantStatusOverlayHelpLocation => 'Unde apare indicatorul:';

  @override
  String get assistantStatusOverlayHelpTopRight =>
      '• Indicatorul apare în colțul din dreapta sus al ecranului';

  @override
  String get assistantStatusOverlayHelpNonIntrusive =>
      '• Este non-intruziv și nu interferează cu utilizarea aplicației';

  @override
  String get assistantStatusOverlayHelpBenefits => 'Beneficii:';

  @override
  String get assistantStatusOverlayHelpVisualFeedback =>
      '• Feedback vizual rapid despre starea asistentului AI';

  @override
  String get assistantStatusOverlayHelpDebugging =>
      '• Util pentru debugging și înțelegerea când AI-ul lucrează';

  @override
  String get assistantStatusOverlayHelpTransparency =>
      '• Transparență despre activitatea asistentului';

  @override
  String get assistantStatusOverlayHelpNote =>
      'Notă: Indicatorul se actualizează automat când pornești sau oprești interacțiunea vocală cu AI-ul.';
}
