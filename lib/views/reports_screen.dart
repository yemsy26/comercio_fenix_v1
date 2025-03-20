import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Importaciones para PDF y compartir
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as sp;
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

import '../services/database_service.dart';
import '../services/activity_log_service.dart'; // Importa el servicio de registro
import '../models/product.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  // Rango de fechas para reporte de ventas
  late DateTime _startDate;
  late DateTime _endDate;

  // Resumen de Ventas
  double totalSales = 0.0;
  int totalInvoices = 0;
  double avgSale = 0.0;

  // Resumen de Inventario
  int totalProductLines = 0;
  int totalItemsInStock = 0;
  double totalInventoryValue = 0.0;
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Por defecto, reporte de hoy
    _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadAllData().then((_) {
      ActivityLogService().record("Reporte cargado para hoy");
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSalesReportData(),
        _loadInventoryData(),
      ]);
      ActivityLogService().record("Reporte actualizado");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar datos: $e")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      await _loadAllData();
      ActivityLogService().record("Rango de fechas actualizado: ${DateFormat('yyyy-MM-dd').format(_startDate)} a ${DateFormat('yyyy-MM-dd').format(_endDate)}");
    }
  }

  Future<void> _loadSalesReportData() async {
    final invoices = await _dbService.getInvoices().first;
    final filtered = invoices.where((inv) {
      return (inv.date.isAtSameMomentAs(_startDate) || inv.date.isAfter(_startDate)) &&
          (inv.date.isAtSameMomentAs(_endDate) || inv.date.isBefore(_endDate));
    }).toList();

    totalInvoices = filtered.length;
    totalSales = 0.0;

    for (var inv in filtered) {
      final saleTotal = inv.products.fold<double>(
        0.0,
            (prev, item) => prev + (item.product.price * item.quantity),
      ) - inv.discount;
      totalSales += saleTotal;
    }
    avgSale = totalInvoices > 0 ? totalSales / totalInvoices : 0.0;
  }

  Future<void> _loadInventoryData() async {
    _allProducts = await _dbService.getProducts().first;
    totalProductLines = _allProducts.length;
    totalItemsInStock = 0;
    totalInventoryValue = 0.0;

    for (var p in _allProducts) {
      totalItemsInStock += p.stock;
      totalInventoryValue += p.price * p.stock;
    }
  }

  /// Exportar reporte (ventas + inventario) en PDF
  Future<void> _exportAllAsPdf() async {
    final doc = pw.Document();

    // Página 1: Ventas
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Reporte de Ventas",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColor(1, 0, 0),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text("Desde: ${DateFormat('yyyy-MM-dd').format(_startDate)}"),
              pw.Text("Hasta: ${DateFormat('yyyy-MM-dd').format(_endDate)}"),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Facturas Totales: $totalInvoices",
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Ventas Totales: \$${totalSales.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text("Venta Promedio: \$${avgSale.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 16),
              // Placeholder para gráfico
              pw.Container(
                width: double.infinity,
                height: 100,
                alignment: pw.Alignment.center,
                color: pdf.PdfColor(0.93, 0.93, 0.93),
                child: pw.Text("Gráfico de Ventas (placeholder)",
                    style: pw.TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    // Página 2: Inventario
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          final topProducts = _getTopValuedProducts();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Reporte de Inventario",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColor(0, 0, 1),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Productos Distintos: $totalProductLines",
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Ítems Totales: $totalItemsInStock",
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text("Valor de Inventario: \$${totalInventoryValue.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 16),
              // Placeholder para gráfico
              pw.Container(
                width: double.infinity,
                height: 100,
                alignment: pw.Alignment.center,
                color: pdf.PdfColor(0.93, 0.93, 0.93),
                child: pw.Text("Gráfico de Inventario (placeholder)",
                    style: pw.TextStyle(fontSize: 16)),
              ),
              pw.SizedBox(height: 16),
              if (topProducts.isNotEmpty) ...[
                pw.Text("Top 5 productos por valor:",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Producto", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Stock", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Precio", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Valor", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...topProducts.map((p) {
                      final value = p.stock * p.price;
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(p.name)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("${p.stock}")),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("\$${p.price.toStringAsFixed(2)}")),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("\$${value.toStringAsFixed(2)}")),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    final pdfData = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/report_all.pdf');
    await file.writeAsBytes(pdfData);
    final xFile = XFile(file.path);
    await sp.Share.shareXFiles([xFile], text: 'Reporte de Ventas e Inventario');
    ActivityLogService().record("Reporte exportado en PDF");
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportes"),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportAllAsPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card: Resumen de Ventas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resumen de Ventas",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem("Facturas Totales", "$totalInvoices"),
                        _buildSummaryItem("Ventas Totales", "\$${totalSales.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem("Desde", DateFormat('yyyy-MM-dd').format(_startDate)),
                        _buildSummaryItem("Hasta", DateFormat('yyyy-MM-dd').format(_endDate)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem("Venta Promedio", "\$${avgSale.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Card: Resumen de Inventario
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resumen de Inventario",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem("Productos Distintos", "$totalProductLines"),
                        _buildSummaryItem("Ítems Totales", "$totalItemsInStock"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem("Valor de Inventario", "\$${totalInventoryValue.toStringAsFixed(2)}"),
                    const SizedBox(height: 20),
                    Text(
                      "Top 5 Productos por Valor",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTopProductsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra la lista top 5 productos
  Widget _buildTopProductsList() {
    final topProducts = _getTopValuedProducts();
    if (topProducts.isEmpty) {
      return const Text("No hay productos en inventario.");
    }
    return Column(
      children: topProducts.map((p) {
        final value = p.stock * p.price;
        return ListTile(
          leading: const Icon(Icons.inventory),
          title: Text(p.name),
          subtitle: Text("Stock: ${p.stock} | \$${p.price.toStringAsFixed(2)} c/u"),
          trailing: Text("\$${value.toStringAsFixed(2)}"),
        );
      }).toList(),
    );
  }

  /// Retorna top 5 productos
  List<Product> _getTopValuedProducts() {
    final sorted = List<Product>.from(_allProducts);
    sorted.sort((a, b) => ((b.stock * b.price).compareTo(a.stock * a.price)));
    return sorted.take(5).toList();
  }
}
