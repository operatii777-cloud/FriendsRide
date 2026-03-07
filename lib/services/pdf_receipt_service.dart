import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/delivery/models/delivery_order_model.dart';
import 'package:friendsride_app/delivery/models/delivery_status.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:friendsride_app/utils/logger.dart';

class PdfReceiptService {
  Future<Uint8List> generateReceipt(Ride ride) async {
    try {
      final pdf = pw.Document();

      // Încărcăm fonturile din assets pentru a suporta diacritice
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

      final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(ride.timestamp);

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'CHITANTA',
                    style: pw.TextStyle(font: boldTtf, fontSize: 20, letterSpacing: 2),
                  ),
                ),
                pw.Center(child: pw.Text('ID Cursa: ${ride.id.substring(0, 10)}...')),
                pw.SizedBox(height: 24),
                pw.Text('Data: $formattedDate'),
                pw.Divider(height: 32),
                pw.Text('Detalii Cursa:', style: pw.TextStyle(font: boldTtf, fontSize: 16)),
                _buildDetailRow('De la:', ride.startAddress, boldTtf),
                _buildDetailRow('La:', ride.destinationAddress, boldTtf),
                pw.SizedBox(height: 16),
                pw.Text('Calcul Pret:', style: pw.TextStyle(font: boldTtf, fontSize: 16)),
                _buildDetailRow('Tarif de baza:', '${ride.baseFare.toStringAsFixed(2)} RON', boldTtf),
                _buildDetailRow('Cost Distanta (${ride.distance.toStringAsFixed(1)} km):', '${(ride.distance * ride.perKmRate).toStringAsFixed(2)} RON', boldTtf),
                _buildDetailRow('Cost Timp (${ride.durationInMinutes?.toStringAsFixed(0) ?? '0'} min):', '${((ride.durationInMinutes ?? 0) * ride.perMinRate).toStringAsFixed(2)} RON', boldTtf),
                if (ride.tip > 0)
                  _buildDetailRow('Bacsis:', '${ride.tip.toStringAsFixed(2)} RON', boldTtf),
                pw.Divider(thickness: 1.5, height: 16),
                _buildDetailRow(
                  'TOTAL PLATIT:',
                  '${ride.totalCost.toStringAsFixed(2)} RON',
                  boldTtf,
                  isTotal: true,
                ),
                pw.Divider(height: 32),
                pw.Center(
                  child: pw.Text(
                    'FriendsRide va multumeste!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

      return pdf.save();
    } catch (e) {
              Logger.error('Error generating receipt: $e', error: e);
      rethrow;
    }
  }

  // NOU: Generare raport lunar
  Future<Uint8List> generateMonthlyReport(List<Ride> rides, bool isDriver) async {
    try {
      final pdf = pw.Document();

      // Încărcăm fonturile din assets pentru a suporta diacritice
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy', 'ro_RO').format(now);
    final roleText = isDriver ? 'Șofer' : 'Pasager';

    // Calculăm statisticile
    final totalRides = rides.length;
    final totalAmount = rides.fold(0.0, (sum, ride) => sum + ride.totalCost);
    final totalEarnings = isDriver 
        ? rides.fold(0.0, (sum, ride) => sum + ride.driverEarnings)
        : 0.0;
    final totalDistance = rides.fold(0.0, (sum, ride) => sum + ride.distance);
    final averageRideValue = totalRides > 0 ? totalAmount / totalRides : 0.0;

    // Grupăm cursele pe zile pentru statistici detaliate
    final Map<String, List<Ride>> ridesByDay = {};
    for (final ride in rides) {
      final dayKey = DateFormat('dd MMMM yyyy').format(ride.timestamp);
      ridesByDay.putIfAbsent(dayKey, () => []).add(ride);
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Pagina ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Header principal
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'RAPORT LUNAR FRIENDSRIDE',
                    style: pw.TextStyle(font: boldTtf, fontSize: 22, letterSpacing: 2),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '$roleText - $monthYear',
                    style: pw.TextStyle(font: boldTtf, fontSize: 16, color: PdfColors.blue),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Secțiunea de statistici generale
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STATISTICI GENERALE',
                    style: pw.TextStyle(font: boldTtf, fontSize: 16),
                  ),
                  pw.SizedBox(height: 15),
                  _buildStatRow('Numărul total de curse:', totalRides.toString(), boldTtf),
                  _buildStatRow('Distanța totală parcursă:', '${totalDistance.toStringAsFixed(1)} km', boldTtf),
                  _buildStatRow('Valoarea totală a curselor:', '${totalAmount.toStringAsFixed(2)} RON', boldTtf),
                  if (isDriver) 
                    _buildStatRow('Câștigurile totale (șofer):', '${totalEarnings.toStringAsFixed(2)} RON', boldTtf),
                  _buildStatRow('Valoarea medie per cursă:', '${averageRideValue.toStringAsFixed(2)} RON', boldTtf),
                  _buildStatRow('Distanța medie per cursă:', '${(totalRides > 0 ? totalDistance / totalRides : 0).toStringAsFixed(1)} km', boldTtf),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Secțiunea de detalii pe zile
            pw.Text(
              'DETALII CURSE PE ZILE',
              style: pw.TextStyle(font: boldTtf, fontSize: 16),
            ),
            pw.SizedBox(height: 15),
            
            // Tabel cu cursele grupate pe zile
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header tabel
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Data', boldTtf, isHeader: true),
                    _buildTableCell('Curse', boldTtf, isHeader: true),
                    _buildTableCell('Distanță (km)', boldTtf, isHeader: true),
                    _buildTableCell('Valoare (RON)', boldTtf, isHeader: true),
                  ],
                ),
                // Rânduri cu datele pe zile
                ...ridesByDay.entries.map((entry) {
                  final dayRides = entry.value;
                  final dayDistance = dayRides.fold(0.0, (sum, ride) => sum + ride.distance);
                  final dayAmount = dayRides.fold(0.0, (sum, ride) => sum + ride.totalCost);
                  
                  return pw.TableRow(
                    children: [
                      _buildTableCell(entry.key, ttf),
                      _buildTableCell(dayRides.length.toString(), ttf),
                      _buildTableCell(dayDistance.toStringAsFixed(1), ttf),
                      _buildTableCell(dayAmount.toStringAsFixed(2), ttf),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Lista detaliată a curselor
            pw.Text(
              'LISTA DETALIATĂ A CURSELOR',
              style: pw.TextStyle(font: boldTtf, fontSize: 16),
            ),
            pw.SizedBox(height: 15),
            
            // Iterăm prin toate cursele
            ...rides.asMap().entries.map((entry) {
              final index = entry.key;
              final ride = entry.value;
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(ride.timestamp);
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'CURSA ${index + 1}',
                          style: pw.TextStyle(font: boldTtf, fontSize: 12),
                        ),
                        pw.Text(
                          formattedDate,
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    _buildRideDetailRow('De la:', ride.startAddress, ttf),
                    _buildRideDetailRow('La:', ride.destinationAddress, ttf),
                    _buildRideDetailRow('Distanță:', '${ride.distance.toStringAsFixed(1)} km', ttf),
                    _buildRideDetailRow('Durată:', '${ride.durationInMinutes?.toStringAsFixed(0) ?? '0'} min', ttf),
                    if (ride.tip > 0)
                      _buildRideDetailRow('Bacșiș:', '${ride.tip.toStringAsFixed(2)} RON', ttf),
                    pw.Divider(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL:',
                          style: pw.TextStyle(font: boldTtf, fontSize: 11),
                        ),
                        pw.Text(
                          '${ride.totalCost.toStringAsFixed(2)} RON',
                          style: pw.TextStyle(font: boldTtf, fontSize: 11),
                        ),
                      ],
                    ),
                    if (isDriver) 
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Câștig șofer:',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.green),
                          ),
                          pw.Text(
                            '${ride.driverEarnings.toStringAsFixed(2)} RON',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.green, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
            
            pw.SizedBox(height: 30),
            
            // Footer cu totale finale
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'SUMAR FINAL',
                    style: pw.TextStyle(font: boldTtf, fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total curse executate:', style: pw.TextStyle(font: boldTtf)),
                      pw.Text(totalRides.toString(), style: pw.TextStyle(font: boldTtf)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Valoare totală:', style: pw.TextStyle(font: boldTtf)),
                      pw.Text('${totalAmount.toStringAsFixed(2)} RON', style: pw.TextStyle(font: boldTtf)),
                    ],
                  ),
                  if (isDriver) 
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Câștiguri totale:', style: pw.TextStyle(font: boldTtf, color: PdfColors.green)),
                        pw.Text('${totalEarnings.toStringAsFixed(2)} RON', style: pw.TextStyle(font: boldTtf, color: PdfColors.green)),
                      ],
                    ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Footer final
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Raport generat automat de FriendsRide',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Data generării: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

      return pdf.save();
    } catch (e) {
              Logger.error('Error generating monthly report: $e', error: e);
      rethrow;
    }
  }

  // NOU: Generare raport zilnic pentru șoferi
  Future<Uint8List> generateDailyDriverReport(List<Ride> rides) async {
    try {
      final pdf = pw.Document();

      // Încărcăm fonturile din assets pentru a suporta diacritice
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

    final today = DateTime.now();
    final dateString = DateFormat('dd MMMM yyyy', 'ro_RO').format(today);

    // Calculăm statisticile zilnice
    final totalRides = rides.length;
    final totalEarnings = rides.fold(0.0, (sum, ride) => sum + ride.driverEarnings);
    final totalRevenue = rides.fold(0.0, (sum, ride) => sum + ride.totalCost);
    final totalDistance = rides.fold(0.0, (sum, ride) => sum + ride.distance);
    final averageEarningsPerRide = totalRides > 0 ? totalEarnings / totalRides : 0.0;
    final averageDistancePerRide = totalRides > 0 ? totalDistance / totalRides : 0.0;

    // Grupăm cursele pe ore pentru statistici detaliate
    final Map<int, List<Ride>> ridesByHour = {};
    for (final ride in rides) {
      final hour = ride.timestamp.hour;
      ridesByHour.putIfAbsent(hour, () => []).add(ride);
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Pagina ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Header principal
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'RAPORT ZILNIC ȘOFER',
                    style: pw.TextStyle(font: boldTtf, fontSize: 22, letterSpacing: 2),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    dateString,
                    style: pw.TextStyle(font: boldTtf, fontSize: 16, color: PdfColors.green),
                  ),
                  pw.Text(
                    'Perioada: 00:00 - 24:00',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Secțiunea de statistici generale
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.green50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STATISTICI GENERALE',
                    style: pw.TextStyle(font: boldTtf, fontSize: 16),
                  ),
                  pw.SizedBox(height: 15),
                  _buildStatRow('Numărul total de curse:', totalRides.toString(), boldTtf),
                  _buildStatRow('Distanța totală parcursă:', '${totalDistance.toStringAsFixed(1)} km', boldTtf),
                  _buildStatRow('Valoarea totală a curselor:', '${totalRevenue.toStringAsFixed(2)} RON', boldTtf),
                  pw.Divider(height: 10, color: PdfColors.green),
                  _buildStatRow('CÂȘTIGURI TOTALE (ȘOFER):', '${totalEarnings.toStringAsFixed(2)} RON', boldTtf, isHighlight: true),
                  pw.SizedBox(height: 10),
                  _buildStatRow('Câștig mediu per cursă:', '${averageEarningsPerRide.toStringAsFixed(2)} RON', boldTtf),
                  _buildStatRow('Distanța medie per cursă:', '${averageDistancePerRide.toStringAsFixed(1)} km', boldTtf),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Secțiunea de activitate pe ore
            if (ridesByHour.isNotEmpty) ...[
              pw.Text(
                'ACTIVITATE PE ORE',
                style: pw.TextStyle(font: boldTtf, fontSize: 16),
              ),
              pw.SizedBox(height: 15),
              
              // Tabel cu activitatea pe ore
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header tabel
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('Ora', boldTtf, isHeader: true),
                      _buildTableCell('Curse', boldTtf, isHeader: true),
                      _buildTableCell('Câștiguri (RON)', boldTtf, isHeader: true),
                      _buildTableCell('Distanță (km)', boldTtf, isHeader: true),
                    ],
                  ),
                  // Rânduri cu datele pe ore (doar orele cu activitate)
                  ...ridesByHour.entries.map((entry) {
                    final hour = entry.key;
                    final hourRides = entry.value;
                    final hourEarnings = hourRides.fold(0.0, (sum, ride) => sum + ride.driverEarnings);
                    final hourDistance = hourRides.fold(0.0, (sum, ride) => sum + ride.distance);
                    
                    return pw.TableRow(
                      children: [
                        _buildTableCell('${hour.toString().padLeft(2, '0')}:00', ttf),
                        _buildTableCell(hourRides.length.toString(), ttf),
                        _buildTableCell(hourEarnings.toStringAsFixed(2), ttf),
                        _buildTableCell(hourDistance.toStringAsFixed(1), ttf),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 30),
            ],
            
            // Lista detaliată a curselor
            pw.Text(
              'LISTA DETALIATĂ A CURSELOR',
              style: pw.TextStyle(font: boldTtf, fontSize: 16),
            ),
            pw.SizedBox(height: 15),
            
            // Iterăm prin toate cursele
            ...rides.asMap().entries.map((entry) {
              final index = entry.key;
              final ride = entry.value;
              final formattedTime = DateFormat('HH:mm').format(ride.timestamp);
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: index % 2 == 0 ? PdfColors.grey50 : null,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'CURSA ${index + 1}',
                          style: pw.TextStyle(font: boldTtf, fontSize: 12),
                        ),
                        pw.Text(
                          'Ora: $formattedTime',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    _buildRideDetailRow('De la:', ride.startAddress, ttf),
                    _buildRideDetailRow('La:', ride.destinationAddress, ttf),
                    _buildRideDetailRow('Distanță:', '${ride.distance.toStringAsFixed(1)} km', ttf),
                    _buildRideDetailRow('Durată:', '${ride.durationInMinutes?.toStringAsFixed(0) ?? '0'} min', ttf),
                    _buildRideDetailRow('Valoare cursă:', '${ride.totalCost.toStringAsFixed(2)} RON', ttf),
                    if (ride.tip > 0)
                      _buildRideDetailRow('Bacșiș primit:', '${ride.tip.toStringAsFixed(2)} RON', ttf),
                    
                    pw.Divider(height: 8, color: PdfColors.green),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'CÂȘTIG ȘOFER:',
                          style: pw.TextStyle(font: boldTtf, fontSize: 11, color: PdfColors.green),
                        ),
                        pw.Text(
                          '${ride.driverEarnings.toStringAsFixed(2)} RON',
                          style: pw.TextStyle(font: boldTtf, fontSize: 11, color: PdfColors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            
            pw.SizedBox(height: 30),
            
            // Footer cu totale finale
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                border: pw.Border.all(color: PdfColors.green),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'SUMAR FINAL ZILNIC',
                    style: pw.TextStyle(font: boldTtf, fontSize: 16, color: PdfColors.green),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total curse executate:', style: pw.TextStyle(font: boldTtf)),
                      pw.Text(totalRides.toString(), style: pw.TextStyle(font: boldTtf)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Distanță totală parcursă:', style: pw.TextStyle(font: boldTtf)),
                      pw.Text('${totalDistance.toStringAsFixed(1)} km', style: pw.TextStyle(font: boldTtf)),
                    ],
                  ),
                  pw.Divider(height: 10, color: PdfColors.green),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL CÂȘTIGURI ZIUA:', style: pw.TextStyle(font: boldTtf, fontSize: 14, color: PdfColors.green)),
                      pw.Text('${totalEarnings.toStringAsFixed(2)} RON', style: pw.TextStyle(font: boldTtf, fontSize: 14, color: PdfColors.green)),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Footer final
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Raport zilnic generat automat de FriendsRide',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Data generării: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

      return pdf.save();
    } catch (e) {
              Logger.error('Error generating daily driver report: $e', error: e);
      rethrow;
    }
  }

  // Funcție ajutătoare pentru statistici (cu highlight opțional)
  pw.Widget _buildStatRow(String label, String value, pw.Font boldFont, {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label, 
            style: pw.TextStyle(
              color: isHighlight ? PdfColors.green : null,
              fontWeight: isHighlight ? pw.FontWeight.bold : null,
            ),
          ),
          pw.Text(
            value, 
            style: pw.TextStyle(
              font: boldFont,
              color: isHighlight ? PdfColors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  // Funcție ajutătoare pentru celulele tabelului
  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isHeader ? font : null,
          fontSize: isHeader ? 11 : 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Funcție ajutătoare pentru detaliile curselor
  pw.Widget _buildRideDetailRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // Funcție ajutătoare pentru a crea rânduri în PDF (din codul original)
  pw.Widget _buildDetailRow(String label, String value, pw.Font boldFont, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                font: isTotal ? boldFont : null,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generează PDF pentru comanda de delivery
  Future<Uint8List> generateDeliveryOrderReceipt(DeliveryOrder order) async {
    try {
      final pdf = pw.Document();

      // Încărcăm fonturile din assets pentru a suporta diacritice
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

      final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'ro_RO').format(order.createdAt);

      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'REZUMAT COMANDA DELIVERY',
                      style: pw.TextStyle(font: boldTtf, fontSize: 20, letterSpacing: 2),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'ID Comandă: ${order.id.substring(0, 10)}...',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('Data: $formattedDate', style: pw.TextStyle(font: boldTtf)),
                  pw.Divider(height: 32),
                  
                  // Detalii comandă
                  pw.Text('Detalii Comandă:', style: pw.TextStyle(font: boldTtf, fontSize: 16)),
                  pw.SizedBox(height: 12),
                  _buildDetailRow('Status:', order.status.getDisplayName('ro'), boldTtf),
                  pw.SizedBox(height: 8),
                  
                  // Adresă livrare
                  pw.Text('Adresă Livrare:', style: pw.TextStyle(font: boldTtf, fontSize: 14)),
                  pw.Text(order.deliveryAddress.address, style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 16),
                  
                  // Produse
                  pw.Text('Produse Comandate:', style: pw.TextStyle(font: boldTtf, fontSize: 16)),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Produs', style: pw.TextStyle(font: boldTtf, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Cant.', style: pw.TextStyle(font: boldTtf, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Preț', style: pw.TextStyle(font: boldTtf, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Total', style: pw.TextStyle(font: boldTtf, fontSize: 12)),
                          ),
                        ],
                      ),
                      // Items
                      ...order.items.map((item) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${item.quantity}x', style: const pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${item.unitPrice.toStringAsFixed(2)} RON', style: const pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${item.totalPrice.toStringAsFixed(2)} RON', style: const pw.TextStyle(fontSize: 11)),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  
                  // Calcul preț
                  pw.Text('Calcul Preț:', style: pw.TextStyle(font: boldTtf, fontSize: 16)),
                  pw.SizedBox(height: 8),
                  _buildDetailRow('Subtotal:', '${order.subtotal.toStringAsFixed(2)} RON', boldTtf),
                  _buildDetailRow('Taxă livrare:', '${order.deliveryFee.toStringAsFixed(2)} RON', boldTtf),
                  _buildDetailRow('Taxă serviciu:', '${order.serviceFee.toStringAsFixed(2)} RON', boldTtf),
                  if (order.discount != null && order.discount! > 0)
                    _buildDetailRow('Reducere:', '-${order.discount!.toStringAsFixed(2)} RON', boldTtf),
                  pw.Divider(thickness: 1.5, height: 16),
                  _buildDetailRow(
                    'TOTAL PLATIT:',
                    '${order.total.toStringAsFixed(2)} RON',
                    boldTtf,
                    isTotal: true,
                  ),
                  pw.SizedBox(height: 16),
                  
                  // Metodă plată
                  pw.Text('Metodă Plată:', style: pw.TextStyle(font: boldTtf, fontSize: 14)),
                  pw.Text(
                    order.paymentMethod == 'card' ? 'Card' : 'Numerar la livrare',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  
                  if (order.metadata?['notes'] != null) ...[
                    pw.SizedBox(height: 16),
                    pw.Text('Note:', style: pw.TextStyle(font: boldTtf, fontSize: 14)),
                    pw.Text(
                      order.metadata!['notes'] as String,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                  
                  pw.Divider(height: 32),
                  pw.Center(
                    child: pw.Text(
                      'FriendsRide Delivery vă mulțumește!',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      Logger.error('Error generating delivery order receipt: $e', error: e);
      rethrow;
    }
  }
}