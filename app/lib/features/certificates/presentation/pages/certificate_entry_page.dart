import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/sites_repository.dart';
import '../../domain/certificate_files.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/attachment_kind.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/certificate_status.dart';
import '../../domain/repositories/certificates_repository.dart';
import '../bloc/certificate_cubit.dart';
import '../certificate_labels.dart';

/// Site-user certificate entry form. It has no Scaffold of its own: the host
/// (the site shell tab or [CertificateEntryPage]) provides it.
class CertificateEntryBody extends StatelessWidget {
  const CertificateEntryBody({super.key});

  @override
  Widget build(BuildContext context) => const _EntryBody();
}

/// Standalone entry page with its own cubit and a single Scaffold.
class CertificateEntryPage extends StatelessWidget {
  const CertificateEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => CertificateCubit(
        context.read<CertificatesRepository>(),
        context.read<SitesRepository>(),
      )..loadSites(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.siteTabEntry),
          actions: [
            IconButton(
              tooltip: l10n.logoutButton,
              onPressed: () => context.read<SessionCubit>().signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const CertificateEntryBody(),
      ),
    );
  }
}

class _EntryBody extends StatefulWidget {
  const _EntryBody();

  @override
  State<_EntryBody> createState() => _EntryBodyState();
}

/// A picked file before validation.
typedef _PickedFile = ({String name, List<int> bytes});

class _EntryBodyState extends State<_EntryBody> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _picker = ImagePicker();
  Site? _site;
  DateTime _date = _today();
  bool _uploading = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  CertificateCubit get _cubit => context.read<CertificateCubit>();

  Certificate? get _openCert {
    final s = _cubit.state;
    return s is CertificateLoaded ? s.certificate : null;
  }

  bool get _editable {
    final cert = _openCert;
    return cert == null || isEditableStatus(cert.status);
  }

  Site? _selectedSite(List<Site> sites) => _site ?? (sites.isEmpty ? null : sites.first);

  String? get _notesValue => _notes.text.trim().isEmpty ? null : _notes.text.trim();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Fills the form from a certificate opened from the records list.
  /// A cleared certificate ([CertificateCubit.newCertificate]) empties it.
  void _syncFrom(CertificateLoaded loaded) {
    final cert = loaded.certificate;
    if (cert == null) {
      setState(() {
        _amount.clear();
        _notes.clear();
        _date = _today();
      });
      return;
    }
    setState(() {
      _amount.text = cert.amount;
      _notes.text = cert.notes ?? '';
      _date = cert.certificateDate;
      _site = loaded.sites.where((s) => s.id == cert.siteId).firstOrNull ?? _site;
    });
  }

  void _scheduleAutoSave() {
    if (!_editable) return;
    final site = _selectedSite(
      _cubit.state is CertificateLoaded ? (_cubit.state as CertificateLoaded).sites : const [],
    );
    _cubit.scheduleAutoSave(
      siteId: site?.id,
      date: _date,
      amount: normalizeAmount(_amount.text) ?? '',
      notes: _notesValue,
    );
  }

  Future<bool> _save({bool announce = true}) async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final state = _cubit.state;
    final site = _selectedSite(state is CertificateLoaded ? state.sites : const []);
    final amount = normalizeAmount(_amount.text);
    if (site == null || amount == null) return false;
    final ok = await _cubit.saveDraft(
      siteId: site.id,
      date: _date,
      amount: amount,
      notes: _notesValue,
    );
    if (ok && announce && mounted) _showMessage(l10n.certificateDraftSaved);
    return ok;
  }

  Future<void> _submit() async {
    if (!await _save(announce: false)) return;
    final cert = _openCert;
    if (cert == null) return;
    await _cubit.submit(cert.id);
  }

  Future<bool> _confirm(String title, String body) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteCertificate(Certificate cert) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      l10n.certificateDeleteConfirmTitle,
      l10n.certificateDeleteConfirmBody,
    );
    if (!confirmed) return;
    if (await _cubit.deleteCertificate(cert.id) && mounted) {
      setState(() {
        _amount.clear();
        _notes.clear();
        _date = _today();
      });
    }
  }

  Future<void> _removeAttachment(String id, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      l10n.attachmentRemoveConfirmTitle,
      l10n.attachmentRemoveConfirmBody(name),
    );
    if (!confirmed) return;
    await _cubit.removeAttachment(id);
  }

  Future<_PickedFile?> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return (name: picked.name, bytes: await picked.readAsBytes());
  }

  Future<_PickedFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final f = result?.files.firstOrNull;
    final bytes = f?.bytes;
    if (f == null || bytes == null) return null;
    return (name: f.name, bytes: bytes);
  }

  /// Validates and uploads a picked file. Returns true when it was stored.
  Future<bool> _upload(AttachmentKind kind, Future<_PickedFile?> Function() pick) async {
    final l10n = AppLocalizations.of(context);
    final cert = _openCert;
    if (cert == null || _uploading) return false;
    final picked = await pick();
    if (picked == null || !mounted) return false;
    final mime = mimeForFileName(picked.name);
    if (mime == null) {
      _showMessage(l10n.attachmentTypeNotAllowed);
      return false;
    }
    if (picked.bytes.length > maxAttachmentBytes) {
      _showMessage(l10n.attachmentTooLarge);
      return false;
    }
    final hash = sha256.convert(picked.bytes).toString();
    final state = _cubit.state;
    final atts = state is CertificateLoaded ? state.attachments : const <Attachment>[];
    if (atts.any((a) => a.sha256 == hash && a.deletedAt == null)) {
      _showMessage(l10n.attachmentDuplicate);
      return false;
    }
    setState(() => _uploading = true);
    try {
      return await _cubit.uploadAttachment(
        certificateId: cert.id,
        kind: kind,
        bytes: picked.bytes,
        fileName: picked.name,
        mime: mime,
        sha256Hex: hash,
        storagePath: buildStoragePath(
          siteId: cert.siteId,
          certificateDate: cert.certificateDate,
          fileName: picked.name,
          newId: () => const Uuid().v4(),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _uploadSignedCopy(Certificate cert) async {
    final session = context.read<SessionCubit>().state;
    final actorId = session is SessionAuthenticated ? session.user.id : null;
    if (actorId == null) return;
    // A retry after a failed finalize reuses the signed copy of this round
    // instead of uploading it again (which the duplicate check would reject).
    // The round starts at approve_for_signing, the last change of the row
    // while it awaits signature; earlier rounds' copies do not count (the
    // server applies the same rule).
    final state = _cubit.state;
    final atts = state is CertificateLoaded ? state.attachments : const <Attachment>[];
    final hasSigned = atts.any(
      (a) =>
          a.kind == AttachmentKind.signed &&
          a.deletedAt == null &&
          !a.uploadedAt.isBefore(cert.updatedAt),
    );
    if (!hasSigned && !await _upload(AttachmentKind.signed, _pickFile)) return;
    await _cubit.finalize(certificateId: cert.id, actorId: actorId);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CertificateCubit, CertificateState>(
      // Sync on an opened certificate, or when the open one is cleared; never
      // while typing (a save only replaces the certificate with itself).
      listenWhen: (prev, curr) =>
          curr is CertificateLoaded &&
          (prev is CertificateLoading ||
              (prev is CertificateLoaded && prev.certificate != null && curr.certificate == null)),
      listener: (context, state) => _syncFrom(state as CertificateLoaded),
      builder: (context, state) => switch (state) {
        CertificateLoading() => const LoadingView(),
        CertificateError(:final failure) => ErrorView(
          message: failureMessage(failure, l10n),
          onRetry: _cubit.loadSites,
        ),
        final CertificateLoaded loaded => _form(context, loaded),
      },
    );
  }

  Widget _form(BuildContext context, CertificateLoaded loaded) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);
    final cert = loaded.certificate;
    final editable = cert == null || isEditableStatus(cert.status);
    final site = _selectedSite(loaded.sites);

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          if (loaded.sites.isNotEmpty)
            DropdownButtonFormField<Site>(
              key: ValueKey(site?.id),
              initialValue: site,
              items: [
                for (final s in loaded.sites) DropdownMenuItem(value: s, child: Text(s.name)),
              ],
              // The site of an existing certificate cannot change.
              onChanged: cert != null
                  ? null
                  : (s) {
                      if (s == null) return;
                      setState(() => _site = s);
                      _scheduleAutoSave();
                    },
              decoration: InputDecoration(labelText: l10n.siteNameLabel),
            ),
          SizedBox(height: spacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.certificateDate),
            subtitle: Text(formatDbDate(_date)),
            trailing: const Icon(Icons.calendar_today),
            enabled: editable,
            onTap: _pickDate,
          ),
          SizedBox(height: spacing.md),
          TextFormField(
            controller: _amount,
            readOnly: !editable,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(labelText: l10n.certificateAmount),
            validator: (v) =>
                normalizeAmount(v ?? '') == null ? l10n.certificateAmountInvalid : null,
            onChanged: (_) => _scheduleAutoSave(),
          ),
          SizedBox(height: spacing.md),
          TextFormField(
            controller: _notes,
            readOnly: !editable,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.certificateNotes),
            onChanged: (_) => _scheduleAutoSave(),
          ),
          if (cert != null) ...[
            SizedBox(height: spacing.lg),
            Text(
              '${l10n.certificateStatus}: ${certificateStatusLabel(cert.status, l10n)}',
              style: theme.textTheme.titleSmall,
            ),
            if (cert.returnNote case final note? when note.isNotEmpty) ...[
              SizedBox(height: spacing.sm),
              Text(
                '${l10n.certificateReturnedNote}: $note',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            SizedBox(height: spacing.md),
            Text(l10n.attachmentUpload, style: theme.textTheme.titleSmall),
            for (final a in loaded.attachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.mime == 'application/pdf' ? Icons.picture_as_pdf : Icons.image_outlined,
                ),
                title: Text(a.fileName),
                subtitle: Text(attachmentKindLabel(a.kind, l10n)),
                // Signed copies are never removable (PROJECT_PLAN 5).
                trailing: editable && a.kind == AttachmentKind.initial
                    ? IconButton(
                        tooltip: l10n.attachmentRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeAttachment(a.id, a.fileName),
                      )
                    : null,
              ),
            if (_uploading) ...[
              const LinearProgressIndicator(),
              SizedBox(height: spacing.xs),
              Text(l10n.attachmentUploading),
            ],
            if (editable)
              Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () =>
                              _upload(AttachmentKind.initial, () => _pickImage(ImageSource.camera)),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.attachmentPickCamera),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _upload(
                            AttachmentKind.initial,
                            () => _pickImage(ImageSource.gallery),
                          ),
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(l10n.attachmentPickGallery),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _upload(AttachmentKind.initial, _pickFile),
                    icon: const Icon(Icons.attach_file),
                    label: Text(l10n.attachmentPickFile),
                  ),
                ],
              ),
          ],
          SizedBox(height: spacing.lg),
          if (editable)
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: site == null ? null : _save,
                    child: Text(l10n.certificateSaveDraft),
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: cert == null ? null : _submit,
                    child: Text(l10n.certificateSubmit),
                  ),
                ),
              ],
            ),
          if (cert != null && editable) ...[
            SizedBox(height: spacing.sm),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _deleteCertificate(cert),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.certificateDelete),
            ),
          ],
          if (cert != null && cert.status == CertificateStatus.awaitingSignature) ...[
            SizedBox(height: spacing.lg),
            FilledButton.icon(
              onPressed: _uploading ? null : () => _uploadSignedCopy(cert),
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.certificateSignedCopy),
            ),
          ],
          if (loaded.actionError case final error?) ...[
            SizedBox(height: spacing.sm),
            Text(
              failureMessage(error, l10n),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
