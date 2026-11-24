import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/sites_repository.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/attachment_kind.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/certificate_status.dart';
import '../../domain/repositories/certificates_repository.dart';

sealed class CertificateState {
  const CertificateState();
}

final class CertificateLoading extends CertificateState {
  const CertificateLoading();
  @override
  bool operator ==(Object other) => other is CertificateLoading;
  @override
  int get hashCode => (CertificateLoading).hashCode;
}

final class CertificateLoaded extends CertificateState {
  const CertificateLoaded({
    required this.sites,
    this.certificate,
    this.attachments = const [],
    this.records = const [],
    this.actionError,
  });

  final List<Site> sites;
  final Certificate? certificate;
  final List<Attachment> attachments;
  final List<Certificate> records;
  final AppFailure? actionError;

  CertificateLoaded copyWith({
    List<Site>? sites,
    Certificate? certificate,
    bool clearCertificate = false,
    List<Attachment>? attachments,
    List<Certificate>? records,
    AppFailure? actionError,
    bool clearActionError = false,
  }) => CertificateLoaded(
    sites: sites ?? this.sites,
    certificate: clearCertificate ? null : (certificate ?? this.certificate),
    attachments: attachments ?? this.attachments,
    records: records ?? this.records,
    actionError: clearActionError ? null : (actionError ?? this.actionError),
  );

  @override
  bool operator ==(Object other) =>
      other is CertificateLoaded &&
      listEquals(other.sites, sites) &&
      other.certificate == certificate &&
      listEquals(other.attachments, attachments) &&
      listEquals(other.records, records) &&
      other.actionError == actionError;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(sites),
    certificate,
    Object.hashAll(attachments),
    Object.hashAll(records),
    actionError,
  );
}

final class CertificateError extends CertificateState {
  const CertificateError(this.failure);
  final AppFailure failure;
  @override
  bool operator ==(Object other) => other is CertificateError && other.failure == failure;
  @override
  int get hashCode => Object.hash(CertificateError, failure);
}

class CertificateCubit extends Cubit<CertificateState> {
  CertificateCubit(
    this._certsRepo,
    this._sitesRepo, {
    this.autoSaveDelay = const Duration(seconds: 2),
  }) : super(const CertificateLoading());

  final CertificatesRepository _certsRepo;
  final SitesRepository _sitesRepo;

  /// Quiet period after the last edit before an automatic draft save.
  final Duration autoSaveDelay;

  Timer? _autoSaveTimer;

  /// Tail of the save queue: saves run one after another so a second save
  /// sees the certificate created by the first and updates it.
  Future<bool> _saveQueue = Future.value(true);

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }

  /// Creates the draft when none is open, otherwise updates the open
  /// draft/returned certificate. Calls are serialized.
  Future<bool> saveDraft({
    required String siteId,
    required DateTime date,
    required String amount,
    String? notes,
  }) {
    final next = _saveQueue.then(
      (_) => _saveNow(siteId: siteId, date: date, amount: amount, notes: notes),
    );
    _saveQueue = next.catchError((Object _) => false);
    return next;
  }

  Future<bool> _saveNow({
    required String siteId,
    required DateTime date,
    required String amount,
    String? notes,
  }) async {
    if (isClosed) return false;
    final current = state is CertificateLoaded ? (state as CertificateLoaded).certificate : null;
    if (current == null) {
      return createDraft(siteId: siteId, certificateDate: date, amount: amount, notes: notes);
    }
    if (current.status != CertificateStatus.draft && current.status != CertificateStatus.returned) {
      _setError(const BusinessRuleFailure('invalid_transition'));
      return false;
    }
    return updateDraft(current.id, certificateDate: date, amount: amount, notes: notes);
  }

  /// Debounced [saveDraft]: only the last call within [autoSaveDelay] saves,
  /// and only when a site is selected and the amount is not blank.
  void scheduleAutoSave({
    required String? siteId,
    required DateTime date,
    required String amount,
    String? notes,
  }) {
    _autoSaveTimer?.cancel();
    if (siteId == null || amount.trim().isEmpty) return;
    _autoSaveTimer = Timer(autoSaveDelay, () {
      if (isClosed) return;
      unawaited(saveDraft(siteId: siteId, date: date, amount: amount, notes: notes));
    });
  }

  /// Soft-deletes [id] and clears the open certificate.
  Future<bool> deleteCertificate(String id) async {
    _autoSaveTimer?.cancel();
    final result = await _certsRepo.delete(id);
    if (isClosed) return result.isRight();
    if (result case Left(value: final failure)) {
      _setError(failure);
      return false;
    }
    if (state case final CertificateLoaded loaded) {
      emit(
        CertificateLoaded(
          sites: loaded.sites,
          records: loaded.records.where((c) => c.id != id).toList(growable: false),
        ),
      );
    }
    return true;
  }

  /// Soft-deletes attachment [id] and reloads the open certificate's files.
  Future<bool> removeAttachment(String id) async {
    final result = await _certsRepo.removeAttachment(id);
    if (isClosed) return result.isRight();
    if (result case Left(value: final failure)) {
      _setError(failure);
      return false;
    }
    await _reloadAttachments();
    return true;
  }

  Future<void> _reloadAttachments() async {
    final certId = state is CertificateLoaded ? (state as CertificateLoaded).certificate?.id : null;
    if (certId == null) return;
    final attResult = await _certsRepo.listAttachments(certId);
    if (isClosed) return;
    switch (attResult) {
      case Right(value: final atts):
        if (state case final CertificateLoaded loaded) {
          emit(loaded.copyWith(attachments: atts, clearActionError: true));
        }
      case Left(value: final failure):
        _setError(failure);
    }
  }

  Future<void> loadSites() async {
    emit(const CertificateLoading());
    final sitesResult = await _sitesRepo.list();
    if (isClosed) return;
    if (sitesResult case Left(value: final failure)) {
      emit(CertificateError(failure));
      return;
    }
    final sites = sitesResult.getOrElse((_) => const <Site>[]);
    emit(CertificateLoaded(sites: sites));
  }

  /// Loads the sites, then the records of the first site (once).
  Future<void> loadSitesAndRecords() async {
    await loadSites();
    if (state case CertificateLoaded(:final sites) when sites.isNotEmpty) {
      await loadRecords(sites.first.id);
    }
  }

  /// Reloads [siteId]'s records, keeping any open certificate.
  Future<void> loadRecords(String siteId) async {
    final result = await _certsRepo.listForSite(siteId);
    if (isClosed) return;
    if (result case Left(value: final failure)) {
      if (state is CertificateLoaded) {
        _setError(failure);
      } else {
        emit(CertificateError(failure));
      }
      return;
    }
    final records = result.getOrElse((_) => const <Certificate>[]);
    if (state case final CertificateLoaded loaded) {
      emit(loaded.copyWith(records: records));
    } else {
      emit(CertificateLoaded(sites: const [], records: records));
    }
  }

  Future<void> openCertificate(String certificateId) async {
    final current = state;
    final sites = current is CertificateLoaded ? current.sites : <Site>[];
    emit(const CertificateLoading());
    final certResult = await _certsRepo.getById(certificateId);
    final attResult = await _certsRepo.listAttachments(certificateId);
    if (isClosed) return;
    if (certResult case Left(value: final failure)) {
      emit(CertificateError(failure));
      return;
    }
    final cert = certResult.getOrElse((_) => throw StateError('unreachable'));
    final atts = attResult.getOrElse((_) => const <Attachment>[]);
    emit(CertificateLoaded(sites: sites, certificate: cert, attachments: atts));
  }

  Future<bool> createDraft({
    required String siteId,
    required DateTime certificateDate,
    required String amount,
    String? notes,
  }) async {
    final result = await _certsRepo.createDraft(
      siteId: siteId,
      certificateDate: certificateDate,
      amount: amount,
      notes: notes,
    );
    return _applyResult(result);
  }

  Future<bool> updateDraft(
    String id, {
    DateTime? certificateDate,
    String? amount,
    String? notes,
  }) async {
    final result = await _certsRepo.updateDraft(
      id,
      certificateDate: certificateDate,
      amount: amount,
      notes: notes,
    );
    return _applyResult(result);
  }

  Future<bool> submit(String id) async {
    final result = await _certsRepo.submit(id);
    return _applyResult(result);
  }

  Future<bool> uploadAttachment({
    required String certificateId,
    required AttachmentKind kind,
    required List<int> bytes,
    required String fileName,
    required String mime,
    required String sha256Hex,
    required String storagePath,
  }) async {
    final result = await _certsRepo.uploadAttachment(
      certificateId: certificateId,
      kind: kind,
      bytes: bytes,
      fileName: fileName,
      mime: mime,
      sha256Hex: sha256Hex,
      storagePath: storagePath,
    );
    if (isClosed) return result.isRight();
    if (result case Left(value: final failure)) {
      _setError(failure);
      return false;
    }
    await _reloadAttachments();
    return true;
  }

  Future<bool> finalize({required String certificateId, required String actorId}) async {
    final result = await _certsRepo.finalize(certificateId: certificateId, actorId: actorId);
    return _applyResult(result);
  }

  Future<bool> _applyResult(Result<Certificate> result) async {
    if (isClosed) return result.isRight();
    if (result case Left(value: final failure)) {
      _setError(failure);
      return false;
    }
    final cert = result.getOrElse((_) => throw StateError('unreachable'));
    if (state case final CertificateLoaded loaded) {
      emit(loaded.copyWith(certificate: cert, clearActionError: true));
    } else {
      emit(CertificateLoaded(sites: const [], certificate: cert));
    }
    return true;
  }

  void _setError(AppFailure failure) {
    if (state case final CertificateLoaded loaded) {
      emit(loaded.copyWith(actionError: failure));
    }
  }

  void clearActionError() {
    if (state case final CertificateLoaded loaded) {
      emit(loaded.copyWith(clearActionError: true));
    }
  }
}
