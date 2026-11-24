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
  }) =>
      CertificateLoaded(
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
  int get hashCode => Object.hash(Object.hashAll(sites), certificate, Object.hashAll(attachments), Object.hashAll(records), actionError);
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
  CertificateCubit(this._certsRepo, this._sitesRepo) : super(const CertificateLoading());

  final CertificatesRepository _certsRepo;
  final SitesRepository _sitesRepo;

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

  Future<void> loadRecords(String siteId) async {
    final current = state;
    final sites = current is CertificateLoaded ? current.sites : <Site>[];
    final result = await _certsRepo.listForSite(siteId);
    if (isClosed) return;
    if (result case Left(value: final failure)) {
      emit(CertificateError(failure));
      return;
    }
    final records = result.getOrElse((_) => const <Certificate>[]);
    emit(CertificateLoaded(sites: sites, records: records));
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
    final result = await _certsRepo.updateDraft(id, certificateDate: certificateDate, amount: amount, notes: notes);
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
    if (result case Left(value: final failure)) {
      _setError(failure);
      return false;
    }
    // reload attachments
    final attResult = await _certsRepo.listAttachments(certificateId);
    if (isClosed) return true;
    if (attResult case Right(value: final atts)) {
      if (state case final CertificateLoaded loaded) {
        emit(loaded.copyWith(attachments: atts, clearActionError: true));
      }
    }
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
