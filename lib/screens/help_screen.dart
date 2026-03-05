import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/help_article_screen.dart';
import 'package:friendsride_app/screens/report_form_screen.dart';
import 'package:friendsride_app/screens/career_screen.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/utils/logger.dart';

class HelpScreen extends StatefulWidget {
  final bool isPassengerMode;

  const HelpScreen({super.key, this.isPassengerMode = true});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  List<Widget> _buildHelpArticle(String title, AppLocalizations l10n) {
    switch (title) {
      case 'cannotRequestRide':
      case 'Nu pot solicita o cursă': {
        return [
          Text(
            l10n.cannotRequestRideContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.checkInternetConnection),
          Text(l10n.ensureGpsEnabled),
          Text(l10n.restartApp),
          Text(l10n.checkValidPayment),
          Text(l10n.contactSupportIfPersists),
        ];
      }
      case 'pickupTimeLonger':
      case 'Timpul de preluare este mai mare decât cel estimat': {
        return [
          Text(
            l10n.pickupTimeLongerContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.unexpectedHeavyTraffic),
          Text(l10n.unfavorableWeather),
          Text(l10n.driverFindingAddress),
          Text(l10n.specialEvents),
          const SizedBox(height: 16),
          Text(
            l10n.contactDriverDirectly,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ];
      }
      case 'rideDidNotHappen':
      case 'Cursa nu a avut loc': {
        return [
          Text(
            l10n.rideDidNotHappenContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.rideStatusInApp),
          Text(l10n.messagesFromDriver),
          Text(l10n.correctLocation),
          const SizedBox(height: 16),
          Text(
            l10n.contactSupportForRefund,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];
      }
      case 'lostItems':
      case 'Obiecte pierdute': {
        return [
          Text(
            l10n.lostItemsContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.contactDriverImmediately),
          Text(l10n.describeLostItem),
          Text(l10n.arrangePickup),
          Text(l10n.reportToSupport),
          const SizedBox(height: 16),
          Text(
            l10n.returnFeeNote,
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
          ),
        ];
      }
      case 'driverDeviatedRoute':
      case 'Șoferul a deviat de la traseu': {
        return [
          Text(
            l10n.driverDeviatedContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.askDriverReason),
          Text(l10n.checkTrafficWorks),
          Text(l10n.reportIfUnjustified),
          const SizedBox(height: 16),
          Text(
            l10n.driversCanChooseAlternatives,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ];
      }
      case 'emergencyAssistanceUsage':
      case 'Utilizarea asistenței de urgență': {
        return [
          Text(
            l10n.emergencyAssistanceUsageContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.call112Quickly),
          Text(l10n.sendLocationToEmergencyContact),
          Text(l10n.reportIncidentToSafetyTeam),
          const SizedBox(height: 16),
          Text(
            l10n.useOnlyRealEmergencies,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
          ),
        ];
      }
      case 'reportAccidentOrUnpleasantEvent':
      case 'Raportează accident sau eveniment neplăcut': {
        return [
          Text(
            l10n.toReportIncident,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.ensureYourSafety),
          Text(l10n.useEmergencyFunctionInApp),
          Text(l10n.describeInDetail),
          Text(l10n.addPhotosIfPossible),
          Text(l10n.cooperateWithInvestigationTeam),
          const SizedBox(height: 16),
          Text(
            l10n.falseReportsCanLead,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
          ),
        ];
      }
      case 'cleaningOrDamageFee':
      case 'Taxă curățenie sau daune': {
        return [
          Text(
            l10n.cleaningFeeTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.cleaningFeeIntro,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.whenFeeApplied,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(l10n.spillingLiquids),
          Text(l10n.soilingSeatsOrFloor),
          Text(l10n.vomitingInVehicle),
          Text(l10n.smokingInVehicle),
          Text(l10n.damagingVehicleElements),
          Text(l10n.leavingFoodOrTrash),
          Text(l10n.persistentOdors),
          const SizedBox(height: 20),
          Text(
            l10n.howFeeProcessWorks,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(l10n.driverDocumentsDamage),
          Text(l10n.driverReportsIncident),
          Text(l10n.teamAnalyzesReport),
          Text(l10n.ifFeeJustified),
          Text(l10n.feeChargedAutomatically),
          Text(l10n.passengerCanContest),
          const SizedBox(height: 20),
          Text(
            l10n.feeAmounts,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lightCleaning,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(l10n.wipingAndVacuuming),
                Text(l10n.removingSmallStains),
                const SizedBox(height: 12),
                Text(
                  l10n.intensiveCleaning,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(l10n.professionalCleaning),
                Text(l10n.deodorizationAndSpecialTreatments),
                const SizedBox(height: 12),
                Text(
                  l10n.repairsAndReplacements,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(l10n.replacingDamagedSeatCovers),
                Text(l10n.repairingDamagedComponents),
                Text(l10n.costsDependOnSeverity),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.yourRightsAsPassenger,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rightToReceivePhotos,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.canContestFee,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rightToObjectiveInvestigation,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.ifContestationJustified,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.howToAvoidFee,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(l10n.doNotConsumeFood),
          Text(l10n.checkShoesNotDirty),
          Text(l10n.notifyDriverIfFeelingUnwell),
          Text(l10n.doNotSmokeInVehicle),
          Text(l10n.treatVehicleWithRespect),
          Text(l10n.takeTrashWithYou),
          const SizedBox(height: 20),
          Text(
            l10n.contestationProcess,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(l10n.accessRideHistory),
          Text(l10n.selectRideForContestation),
          Text(l10n.pressContestFee),
          Text(l10n.addRelevantEvidence),
          Text(l10n.teamWillReanalyze),
          Text(l10n.receiveDetailedResponse),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.haveQuestionsOrNeedAssistance,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                ),
                const SizedBox(height: 12),
                Text(l10n.emailSupport),
                Text(l10n.phoneSupport),
                Text(l10n.chatInApp),
                Text(l10n.scheduleSupport),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importantToRemember,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.feeOnlyAppliedWithClearEvidence,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
          ),
        ];
      }
      case 'howToActivateDriverMode':
      case 'Cum activez modul șofer partener Friends': {
        return [
          Text(
            l10n.toBecomeDriverPartner,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.checkConditions,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.validLicenseRequired),
          const SizedBox(height: 12),
          Text(
            l10n.prepareDocuments,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.documentsNeeded),
          const SizedBox(height: 12),
          Text(
            l10n.completeApplication,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.accessCareerSection),
          const SizedBox(height: 12),
          Text(
            l10n.submitDocuments,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.uploadClearPhotos),
          const SizedBox(height: 12),
          Text(
            l10n.applicationVerification,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.teamWillVerify),
          const SizedBox(height: 12),
          Text(
            l10n.receiveActivationCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.afterApproval),
          const SizedBox(height: 12),
          Text(
            l10n.activateAccount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.enterCodeInApp),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usefulTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.ensureDocumentsValid,
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ];
      }
      case 'ratesAndPayments':
      case 'Tarife și plăți': {
        return [
          Text(
            l10n.ratesAndPaymentsInfo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.ratesCalculatedAutomatically),
          Text(l10n.paymentMadeAutomatically),
          Text(l10n.canSeeRateDetails),
          Text(l10n.inCaseOfPaymentProblems),
          const SizedBox(height: 16),
          Text(
            l10n.forCurrentRatesDetails,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ];
      }
      case 'deliveryOrderRequest':
      case 'Solicitare comandă livrare': {
        return [
          Text(
            l10n.deliveryServices,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.currentlyFocusedOnTransport),
          const SizedBox(height: 12),
          Text(l10n.deliveryServicesAvailableSoon),
          const SizedBox(height: 16),
          Text(
            l10n.weWillNotifyYou,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
          ),
        ];
      }
      case 'appFunctioningProblems':
      case 'Probleme de funcționare a aplicației': {
        return [
          Text(
            l10n.ifAppNotWorkingCorrectly,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.restartApp),
          Text(l10n.checkInternetConnection),
          Text(l10n.updateAppToLatest),
          Text(l10n.restartPhone),
          Text(l10n.reinstallAppIfPersists),
          const SizedBox(height: 16),
          Text(
            l10n.ifProblemContinues,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];
      }
      case 'paymentMethods':
      case 'Metode de plată': {
        return [
          Text(
            l10n.paymentMethodsHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.addingPaymentMethod,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.goToWalletSection),
          Text(l10n.tapAddPaymentMethod),
          Text(l10n.selectCardOrCash),
          Text(l10n.enterCardDetails),
          Text(l10n.savePaymentMethod),
          const SizedBox(height: 16),
          Text(
            l10n.managingPaymentMethods,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.viewAllMethodsInWallet),
          Text(l10n.editOrDeleteMethods),
          Text(l10n.setDefaultPaymentMethod),
          const SizedBox(height: 16),
          Text(
            l10n.paymentMethodsTypes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.creditDebitCards),
          Text(l10n.cashPayment),
          Text(l10n.walletBalance),
          const SizedBox(height: 16),
          Text(
            l10n.paymentSecurity,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.allPaymentsSecure),
          Text(l10n.cardDetailsEncrypted),
          Text(l10n.pciCompliant),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentMethodTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.youCanSendToContact,
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ];
      }
      case 'vouchers':
      case 'Vouchere': {
        return [
          Text(
            l10n.vouchersHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.addingVoucher,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.goToWalletSection),
          Text(l10n.tapVouchersSection),
          Text(l10n.tapAddVoucherCode),
          Text(l10n.enterVoucherCode),
          Text(l10n.applyVoucher),
          const SizedBox(height: 16),
          Text(
            l10n.usingVouchers,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.vouchersAppliedAutomatically),
          Text(l10n.checkVoucherStatus),
          Text(l10n.voucherExpiryInfo),
          const SizedBox(height: 16),
          Text(
            l10n.voucherTypes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.percentageDiscount),
          Text(l10n.fixedAmountDiscount),
          Text(l10n.freeRideVoucher),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voucherTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.oneVoucherPerRide,
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
        ];
      }
      case 'wallet':
      case 'Portofel': {
        return [
          Text(
            l10n.walletHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.walletOverview,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.walletOverviewInfo),
          const SizedBox(height: 16),
          Text(
            l10n.friendsRideCash,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.friendsRideCashInfo),
          Text(l10n.addFundsToWallet),
          Text(l10n.useWalletForPayments),
          const SizedBox(height: 16),
          Text(
            l10n.walletSections,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.paymentMethodsSection),
          Text(l10n.vouchersSection),
          Text(l10n.rideProfilesSection),
          Text(l10n.promotionsSection),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walletTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.walletBalanceNeverExpires,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ];
      }
      case 'subscriptions':
      case 'Abonamente și Promoții':
      case 'Subscriptions and Promotions': {
        return [
          Text(
            l10n.subscriptionsHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.subscriptionsHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpPlans,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpBasic),
          Text(l10n.subscriptionsHelpPlus),
          Text(l10n.subscriptionsHelpPremium),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpHowToSubscribe,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpGoToMenu),
          Text(l10n.subscriptionsHelpTapSubscriptions),
          Text(l10n.subscriptionsHelpSelectPlan),
          Text(l10n.subscriptionsHelpCompletePayment),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpPromotions,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpPromotionsInfo),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpReferral,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpReferralInfo),
        ];
      }
      case 'splitPayment':
      case 'Split Payment':
      case 'Împărțirea Costului': {
        return [
          Text(
            l10n.splitPaymentHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.splitPaymentHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.splitPaymentHelpHowToCreate,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.splitPaymentHelpAfterRide),
          Text(l10n.splitPaymentHelpSelectPeople),
          Text(l10n.splitPaymentHelpShareLink),
          Text(l10n.splitPaymentHelpParticipantsAccept),
          const SizedBox(height: 16),
          Text(
            l10n.splitPaymentHelpHowToAccept,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.splitPaymentHelpReceiveLink),
          Text(l10n.splitPaymentHelpTapAccept),
          Text(l10n.splitPaymentHelpSelectPayment),
          Text(l10n.splitPaymentHelpCompletePayment),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              l10n.splitPaymentHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ),
        ];
      }
      case 'rideSharing':
      case 'Ride Sharing':
      case 'Curse Partajate': {
        return [
          Text(
            l10n.rideSharingHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.rideSharingHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.rideSharingHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.rideSharingHelpDuringRequest),
          Text(l10n.rideSharingHelpSystemMatches),
          Text(l10n.rideSharingHelpIfMatchFound),
          const SizedBox(height: 16),
          Text(
            l10n.rideSharingHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.rideSharingHelpCostReduction),
          Text(l10n.rideSharingHelpEcoFriendly),
          Text(l10n.rideSharingHelpSocial),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              l10n.rideSharingHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
            ),
          ),
        ];
      }
      case 'modifyDestination':
      case 'Modify Destination':
      case 'Modificare Destinație': {
        return [
          Text(
            l10n.modifyDestinationHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.modifyDestinationHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.modifyDestinationHelpHowToModify,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.modifyDestinationHelpDuringRide),
          Text(l10n.modifyDestinationHelpTapModify),
          Text(l10n.modifyDestinationHelpSelectNew),
          Text(l10n.modifyDestinationHelpConfirm),
          Text(l10n.modifyDestinationHelpRouteRecalculated),
          const SizedBox(height: 16),
          Text(
            l10n.modifyDestinationHelpLimitations,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(l10n.modifyDestinationHelpCannotModifyCompleted),
          Text(l10n.modifyDestinationHelpPriceMayChange),
          Text(l10n.modifyDestinationHelpDriverNotified),
        ];
      }
      case 'lowDataMode':
      case 'Mod date reduse':
      case 'Low data mode': {
        return [
          Text(
            l10n.lowDataModeHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.lowDataModeHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.lowDataModeHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.lowDataModeHelpGoToMenu),
          Text(l10n.lowDataModeHelpTapToggle),
          Text(l10n.lowDataModeHelpActivate),
          const SizedBox(height: 16),
          Text(
            l10n.lowDataModeHelpWhatItDoes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.lowDataModeHelpReducesImages),
          Text(l10n.lowDataModeHelpLimitsAnimations),
          Text(l10n.lowDataModeHelpOptimizesMaps),
          Text(l10n.lowDataModeHelpReducesSync),
          const SizedBox(height: 16),
          Text(
            l10n.lowDataModeHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.lowDataModeHelpSavesData),
          Text(l10n.lowDataModeHelpFasterLoading),
          Text(l10n.lowDataModeHelpBatteryLife),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              l10n.lowDataModeHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ),
        ];
      }
      case 'highContrastUI':
      case 'Interfață contrast ridicat':
      case 'High-contrast UI': {
        return [
          Text(
            l10n.highContrastUIHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.highContrastUIHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.highContrastUIHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.highContrastUIHelpGoToMenu),
          Text(l10n.highContrastUIHelpTapToggle),
          Text(l10n.highContrastUIHelpActivate),
          const SizedBox(height: 16),
          Text(
            l10n.highContrastUIHelpWhatItDoes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.highContrastUIHelpIncreasesContrast),
          Text(l10n.highContrastUIHelpBolderText),
          Text(l10n.highContrastUIHelpClearerIcons),
          Text(l10n.highContrastUIHelpBetterVisibility),
          const SizedBox(height: 16),
          Text(
            l10n.highContrastUIHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.highContrastUIHelpAccessibility),
          Text(l10n.highContrastUIHelpReadability),
          Text(l10n.highContrastUIHelpOutdoorUse),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              l10n.highContrastUIHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
            ),
          ),
        ];
      }
      case 'assistantStatusOverlay':
      case 'Suprapunere status asistent':
      case 'Assistant status overlay': {
        return [
          Text(
            l10n.assistantStatusOverlayHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.assistantStatusOverlayHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpGoToMenu),
          Text(l10n.assistantStatusOverlayHelpTapToggle),
          Text(l10n.assistantStatusOverlayHelpActivate),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpWhatItShows,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpWorking),
          Text(l10n.assistantStatusOverlayHelpWaiting),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpLocation,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpTopRight),
          Text(l10n.assistantStatusOverlayHelpNonIntrusive),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpVisualFeedback),
          Text(l10n.assistantStatusOverlayHelpDebugging),
          Text(l10n.assistantStatusOverlayHelpTransparency),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              l10n.assistantStatusOverlayHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
            ),
          ),
        ];
      }
      default:
        return [
          Text(
            l10n.contentComingSoon,
            style: const TextStyle(fontSize: 16),
          ),
        ];
    }
  }

  void _showDriverActivationProcedure(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cum activez modul șofer partener Friends'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pentru a deveni șofer partener FriendsRide, urmează acești pași:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStep('1', 'Verifică condițiile',
                'Trebuie să ai permis de conducere valabil, experiență de minim 2 ani și vârsta de minim 21 de ani.'),
              _buildStep('2', 'Pregătește documentele',
                'Ai nevoie de: permis de conducere, carte de identitate, certificat de înmatriculare auto, ITP valabil și asigurarea RCA.'),
              _buildStep('3', 'Completează aplicația',
                'Accesează secțiunea "Carieră" din meniul principal și completează formularul online cu datele tale.'),
              _buildStep('4', 'Transmite documentele',
                'Încarcă fotografii clare cu toate documentele necesare prin platforma online.'),
              _buildStep('5', 'Verificarea aplicației',
                'Echipa noastră va verifica documentele în maxim 48 de ore lucrătoare.'),
              _buildStep('6', 'Primește codul de activare',
                'După aprobare, vei primi un cod unic prin email/SMS pentru activarea contului de șofer.'),
              _buildStep('7', 'Activează contul',
                'Introdu codul în aplicație și începe să câștigi bani conducând!'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Sfat util:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Asigură-te că toate documentele sunt valabile și fotografiile sunt clare pentru o procesare rapidă.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Închide'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CareerScreen())
              );
            },
            child: const Text('Aplică acum'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHelpTopic(BuildContext context, String title) {
    // --- MODIFICARE: Am eliminat 'Taxă curățenie sau daune' din lista specială ---
    const reportTopics = [
      'Obiecte pierdute',
      'Șoferul a deviat de la traseu',
      'Raportează accident sau eveniment neplăcut',
    ];

    if (reportTopics.contains(title)) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => ReportFormScreen(reportType: title)));
    } else if (title == 'Cum activez modul șofer partener Friends') {
      _showDriverActivationProcedure(context);
    } else {
      final l10n = AppLocalizations.of(context)!;
      final content = _buildHelpArticle(title, l10n);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) =>
                  HelpArticleScreen(articleTitle: title, contentWidgets: content)));
    }
  }

  void _showPasswordResetDialog() {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resetare Parolă'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Introduceți adresa de email asociată contului dumneavoastră.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Introduceți o adresă de email validă.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  String email = emailController.text.trim();
                  
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); 
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Se trimite emailul de resetare...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Un email de resetare a parolei a fost trimis. Verificați-vă inbox-ul (inclusiv folderul Spam)!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 8),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String message = 'A apărut o eroare la trimiterea email-ului de resetare.';
                    if (e.code == 'user-not-found') {
                      message = 'Nu există niciun cont cu această adresă de email.';
                    } else if (e.message != null) {
                      message = e.message!;
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    Logger.error('Error sending password reset email from HelpScreen: $e', error: e);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('A apărut o eroare neașteptată.'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Resetează Parola'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpTopic(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () => _navigateToHelpTopic(context, title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpCenter),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.frequentlyAskedQuestions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildHelpTopic(
            context,
            icon: Icons.search_off_outlined,
            title: l10n.cannotRequestRide,
          ),
          _buildHelpTopic(
            context,
            icon: Icons.timer_off_outlined,
            title: l10n.pickupTimeLonger,
          ),
          _buildHelpTopic(
            context,
            icon: Icons.wrong_location_outlined,
            title: l10n.rideDidNotHappen,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.work_outline,
            title: l10n.lostItems,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.alt_route_outlined,
            title: l10n.driverDeviatedRoute,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.warning_amber_rounded,
            title: l10n.emergencyAssistanceUsage,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.report_gmailerrorred_outlined,
            title: l10n.reportIncidentTitle,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.cleaning_services_outlined,
            title: l10n.cleaningOrDamageFee,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.credit_card_off_outlined,
            title: l10n.ratesAndPayments,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.payment_outlined,
            title: l10n.paymentMethods,
            onTap: () {
              final content = _buildHelpArticle('paymentMethods', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.paymentMethods,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.card_membership_outlined,
            title: l10n.subscriptions,
            onTap: () {
              final content = _buildHelpArticle('subscriptions', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.subscriptionsHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.wallet,
            onTap: () {
              final content = _buildHelpArticle('wallet', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.walletHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.local_offer_outlined,
            title: l10n.vouchers,
            onTap: () {
              final content = _buildHelpArticle('vouchers', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.vouchersHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.account_balance_outlined,
            title: l10n.splitPayment,
            onTap: () {
              final content = _buildHelpArticle('splitPayment', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.splitPaymentHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.group_outlined,
            title: l10n.rideSharingHelpTitle.split(' - ').first, // "Ride Sharing"
            onTap: () {
              final content = _buildHelpArticle('rideSharing', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.rideSharingHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.edit_location_outlined,
            title: l10n.modifyDestination,
            onTap: () {
              final content = _buildHelpArticle('modifyDestination', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.modifyDestinationHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.delivery_dining_outlined,
            title: l10n.deliveryOrderRequest,
          ),
           _buildHelpTopic(
            context,
            icon: Icons.bug_report_outlined,
            title: l10n.appFunctioningProblems,
          ),
          const Divider(),
          _buildHelpTopic(
            context,
            icon: Icons.data_saver_on_outlined,
            title: l10n.lowDataMode,
            onTap: () {
              final content = _buildHelpArticle('lowDataMode', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.lowDataModeHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.contrast_outlined,
            title: l10n.highContrastUI,
            onTap: () {
              final content = _buildHelpArticle('highContrastUI', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.highContrastUIHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
           _buildHelpTopic(
            context,
            icon: Icons.assistant_outlined,
            title: l10n.assistantStatusOverlay,
            onTap: () {
              final content = _buildHelpArticle('assistantStatusOverlay', l10n);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: l10n.assistantStatusOverlayHelpTitle,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildHelpTopic(
            context,
            icon: Icons.lock_reset_outlined,
            title: l10n.forgotPassword,
            onTap: _showPasswordResetDialog, 
          ),
          
          if (widget.isPassengerMode)
            _buildHelpTopic(
              context,
              icon: Icons.drive_eta,
              title: l10n.howToActivateDriverMode,
            ),
        ],
      ),
    );
  }
}