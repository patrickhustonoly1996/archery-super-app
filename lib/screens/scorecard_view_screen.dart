import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/world_archery_scorecard.dart';
import '../widgets/signature_pad.dart';
import '../services/signature_service.dart';
import '../services/scorecard_export_service.dart';

/// Full screen scorecard view with signatures and export functionality.
/// Can be used for live sessions or reviewing completed sessions.
class ScorecardViewScreen extends StatefulWidget {
  final String sessionId;
  final bool isLive;

  const ScorecardViewScreen({
    super.key,
    required this.sessionId,
    this.isLive = false,
  });

  @override
  State<ScorecardViewScreen> createState() => _ScorecardViewScreenState();
}

class _ScorecardViewScreenState extends State<ScorecardViewScreen> {
  late SignatureService _signatureService;
  Session? _session;
  RoundType? _roundType;
  List<End> _ends = [];
  List<List<Arrow>> _endArrows = [];
  bool _isLoading = true;

  // Archer profile
  String _archerName = '';
  String? _archerDob;
  String? _archerDivision;
  String? _archerBowClass;
  Uint8List? _archerSignature;
  Uint8List? _witnessSignature;

  // Editing state
  bool _isEditingName = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    _signatureService = SignatureService(db);

    // Load session data
    final session = await db.getSession(widget.sessionId);
    if (session == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final roundType = await db.getRoundType(session.roundTypeId);
    final ends = await db.getEndsForSession(session.id);
    final endArrows = <List<Arrow>>[];

    for (final end in ends) {
      final arrows = await db.getArrowsForEnd(end.id);
      endArrows.add(arrows);
    }

    // Load archer profile
    final profile = await _signatureService.getArcherProfile();
    final witnessSignature = await _signatureService.getWitnessSignature(session.id);

    if (mounted) {
      setState(() {
        _session = session;
        _roundType = roundType;
        _ends = ends;
        _endArrows = endArrows;
        _archerName = profile.name ?? '';
        _archerDob = profile.dob;
        _archerDivision = profile.division;
        _archerBowClass = profile.bowClass;
        _archerSignature = profile.signature;
        _witnessSignature = witnessSignature;
        _nameController.text = _archerName;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveArcherName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await _signatureService.saveArcherName(name);
      setState(() {
        _archerName = name;
        _isEditingName = false;
      });
    }
  }

  Future<void> _onArcherSignatureChanged(Uint8List? signature) async {
    await _signatureService.saveArcherSignature(signature);
    setState(() => _archerSignature = signature);
  }

  Future<void> _onWitnessSignatureChanged(Uint8List? signature) async {
    if (_session != null) {
      await _signatureService.saveWitnessSignature(_session!.id, signature);
      setState(() => _witnessSignature = signature);
    }
  }

  Future<void> _exportPdf() async {
    if (_session == null || _roundType == null) return;

    try {
      final pdfBytes = await ScorecardExportService.generatePdf(
        session: _session!,
        roundType: _roundType!,
        ends: _ends,
        endArrows: _endArrows,
        archerName: _archerName.isNotEmpty ? _archerName : 'Unknown',
        archerDob: _archerDob,
        division: _archerDivision,
        bowClass: _archerBowClass,
        eventName: null,
        location: _session!.location,
        archerSignature: _archerSignature,
        witnessSignature: _witnessSignature,
      );

      final date = _session!.completedAt ?? _session!.startedAt;
      final filename = '${_roundType!.name}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.pdf';

      await ScorecardExportService.sharePdf(pdfBytes, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scorecard')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_session == null || _roundType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scorecard')),
        body: const Center(child: Text('Session not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_roundType!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // World Archery format scorecard with integrated signatures
            WorldArcheryScorecardWidget(
              session: _session,
              roundType: _roundType,
              ends: _ends,
              endArrows: _endArrows,
              currentEndArrows: const [],
              currentEndNumber: _ends.length + 1,
              archerName: _archerName.isNotEmpty ? _archerName : null,
              division: _archerDivision,
              bowClass: _archerBowClass,
              eventName: _session!.sessionType == 'competition' ? _session!.location : null,
              eventLocation: _session!.location,
              eventDate: _session!.completedAt ?? _session!.startedAt,
              archerSignature: _archerSignature,
              witnessSignature: _witnessSignature,
              onArcherSignatureChanged: _onArcherSignatureChanged,
              onWitnessSignatureChanged: _onWitnessSignatureChanged,
              showSignatures: true,
              isLive: widget.isLive,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Archer name edit section (tap to edit)
            _buildArcherNameEdit(),

            const SizedBox(height: AppSpacing.lg),

            // Signature capture section (full-size pads for signing)
            _buildSignatureCapture(),

            const SizedBox(height: AppSpacing.xl),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildArcherNameEdit() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARCHER PROFILE',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Name field
          Row(
            children: [
              Expanded(
                child: _isEditingName
                    ? TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.surfaceLight),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.gold),
                          ),
                        ),
                        onSubmitted: (_) => _saveArcherName(),
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _isEditingName = true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Name',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _archerName.isNotEmpty ? _archerName : 'Tap to enter',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                color: _archerName.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_isEditingName)
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.gold),
                  onPressed: _saveArcherName,
                )
              else
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                  onPressed: () => setState(() => _isEditingName = true),
                ),
            ],
          ),

          // Note about auto-fill
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your name will auto-fill on future scorecards.',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCapture() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAPTURE SIGNATURES',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SignaturePad(
                  label: 'Archer Signature',
                  savedSignature: _archerSignature,
                  onSignatureChanged: _onArcherSignatureChanged,
                  width: double.infinity,
                  height: 100,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SignaturePad(
                  label: 'Witness Signature',
                  savedSignature: _witnessSignature,
                  onSignatureChanged: _onWitnessSignatureChanged,
                  width: double.infinity,
                  height: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your archer signature is saved and will auto-fill on future scorecards.',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
