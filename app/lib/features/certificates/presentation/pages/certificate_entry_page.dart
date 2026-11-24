import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/sites_repository.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../domain/entities/attachment_kind.dart';
import '../../domain/entities/certificate_status.dart';
import '../../domain/repositories/certificates_repository.dart';
import '../bloc/certificate_cubit.dart';

/// Site-user certificate entry screen. Owns a [CertificateCubit] and lets the
/// user create/edit a draft, attach files, submit, and finalize with a signed
/// copy.
class CertificateEntryPage extends StatelessWidget {
  const CertificateEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CertificateCubit(
        context.read<CertificatesRepository>(),
        context.read<SitesRepository>(),
      )..loadSites(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  Site? _site;
  DateTime _date = DateTime.now();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _sha256(List<int> bytes) => sha256.convert(bytes).toString();

  Future<void> _pickSite(Site site) async {
    setState(() => _site = site);
    // Load existing certificates for the site is not wired here; the user
    // creates a new draft. A records list arrives in a follow-up task.
  }

  Future<void> _createDraft(BuildContext context) async {
    final cubit = context.read<CertificateCubit>();
    final site = _site;
    if (site == null) return;
    final amount = _amount.text.trim();
    if (amount.isEmpty) return;
    await cubit.createDraft(
      siteId: site.id,
      certificateDate: _date,
      amount: amount,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<CertificateCubit>();
    final cert = (cubit.state as CertificateLoaded?)?.certificate;
    if (cert == null) return;
    await cubit.submit(cert.id);
  }

  Future<void> _uploadImage(BuildContext context, ImageSource source) async {
    final cubit = context.read<CertificateCubit>();
    final cert = (cubit.state as CertificateLoaded?)?.certificate;
    if (cert == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).attachmentTooLarge)),
        );
      }
      return;
    }
    final hash = _sha256(bytes);
    final atts = (cubit.state as CertificateLoaded).attachments;
    if (atts.any((a) => a.sha256 == hash && a.deletedAt == null)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).attachmentDuplicate)),
        );
      }
      return;
    }
    final path = '${cert.siteId}/${_date.year}/${_date.month}/${_date.day}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    await cubit.uploadAttachment(
      certificateId: cert.id,
      kind: AttachmentKind.initial,
      bytes: bytes,
      fileName: picked.name,
      mime: 'image/jpeg',
      sha256Hex: hash,
      storagePath: path,
    );
  }

  Future<void> _uploadFile(BuildContext context) async {
    final cubit = context.read<CertificateCubit>();
    final cert = (cubit.state as CertificateLoaded?)?.certificate;
    if (cert == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    if (bytes.length > 2 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).attachmentTooLarge)),
        );
      }
      return;
    }
    final hash = _sha256(bytes);
    final atts = (cubit.state as CertificateLoaded).attachments;
    if (atts.any((a) => a.sha256 == hash && a.deletedAt == null)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).attachmentDuplicate)),
        );
      }
      return;
    }
    final mime = f.extension == 'pdf' ? 'application/pdf' : 'image/jpeg';
    final path = '${cert.siteId}/${_date.year}/${_date.month}/${_date.day}/${DateTime.now().millisecondsSinceEpoch}_${f.name}';
    await cubit.uploadAttachment(
      certificateId: cert.id,
      kind: AttachmentKind.initial,
      bytes: bytes,
      fileName: f.name,
      mime: mime,
      sha256Hex: hash,
      storagePath: path,
    );
  }

  Future<void> _uploadSignedCopy(BuildContext context) async {
    final cubit = context.read<CertificateCubit>();
    final cert = (cubit.state as CertificateLoaded?)?.certificate;
    if (cert == null) return;
    final session = context.read<SessionCubit>().state;
    final actorId = session is SessionAuthenticated ? session.user.id : null;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    if (bytes.length > 2 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).attachmentTooLarge)),
        );
      }
      return;
    }
    final hash = _sha256(bytes);
    final path = '${cert.siteId}/${_date.year}/${_date.month}/${_date.day}/signed_${DateTime.now().millisecondsSinceEpoch}_${f.name}';
    final mime = f.extension == 'pdf' ? 'application/pdf' : 'image/jpeg';
    await cubit.uploadAttachment(
      certificateId: cert.id,
      kind: AttachmentKind.signed,
      bytes: bytes,
      fileName: f.name,
      mime: mime,
      sha256Hex: hash,
      storagePath: path,
    );
    if (actorId != null) {
      final ok = await cubit.finalize(certificateId: cert.id, actorId: actorId);
      if (context.mounted && !ok) {
        final err = (cubit.state as CertificateLoaded).actionError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err != null ? failureMessage(err, AppLocalizations.of(context)) : AppLocalizations.of(context).errorServer)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CertificateCubit, CertificateState>(
      listener: (context, state) {
        if (state is CertificateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failureMessage(state.failure, l10n))),
          );
        }
      },
      builder: (context, state) {
        if (state is CertificateLoading) return const LoadingView();
        if (state is CertificateError) {
          return ErrorView(message: failureMessage(state.failure, l10n), onRetry: () => context.read<CertificateCubit>().loadSites());
        }
        final loaded = state as CertificateLoaded;
        final cert = loaded.certificate;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.siteHomeTitle),
            actions: [
              IconButton(
                tooltip: l10n.logoutButton,
                onPressed: () => context.read<SessionCubit>().signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loaded.sites.isNotEmpty)
                  DropdownButtonFormField<Site>(
                    initialValue: _site ?? loaded.sites.first,
                    items: loaded.sites
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (s) {
                      if (s != null) _pickSite(s);
                    },
                    decoration: InputDecoration(labelText: l10n.siteNameLabel),
                  ),
                SizedBox(height: spacing.md),
                ListTile(
                  title: Text(l10n.certificateDate),
                  subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                SizedBox(height: spacing.md),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.certificateAmount),
                ),
                SizedBox(height: spacing.md),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.certificateNotes),
                ),
                SizedBox(height: spacing.lg),
                if (cert != null) ...[
                  Text('${l10n.certificateStatus}: ${cert.status.name}',
                      style: theme.textTheme.titleSmall),
                  if (cert.returnNote != null && cert.returnNote!.isNotEmpty) ...[
                    SizedBox(height: spacing.sm),
                    Text('${l10n.certificateReturnedNote}: ${cert.returnNote}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                  SizedBox(height: spacing.md),
                  Text(l10n.attachmentUpload, style: theme.textTheme.titleSmall),
                  ...loaded.attachments.map((a) => ListTile(
                        title: Text(a.fileName),
                        subtitle: Text(a.kind.name),
                      )),
                  Wrap(
                    spacing: spacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _uploadImage(context, ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.attachmentPickImage),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _uploadImage(context, ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: Text(l10n.attachmentPickImage),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _uploadFile(context),
                        icon: const Icon(Icons.attach_file),
                        label: Text(l10n.attachmentPickFile),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                ],
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => _createDraft(context),
                        child: Text(l10n.certificateSaveDraft),
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: cert == null ? null : () => _submit(context),
                        child: Text(l10n.certificateSubmit),
                      ),
                    ),
                  ],
                ),
                if (cert != null && cert.status == CertificateStatus.awaitingSignature) ...[
                  SizedBox(height: spacing.lg),
                  FilledButton.icon(
                    onPressed: () => _uploadSignedCopy(context),
                    icon: const Icon(Icons.upload_file),
                    label: Text(l10n.certificateSignedCopy),
                  ),
                ],
                if (loaded.actionError != null) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    failureMessage(loaded.actionError!, l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
