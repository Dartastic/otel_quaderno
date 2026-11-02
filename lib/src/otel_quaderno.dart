// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_quaderno_suppression.dart';

const _tracerName = 'dartastic_otel_libs_quaderno';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class QuadernoResult {
  /// Creates a result.
  const QuadernoResult({
    this.itemCount,
    this.documentId,
    this.kind,
    this.state,
    this.taxRegime,
    this.country,
    this.vatNumberValid,
    this.b2b,
    this.evidenceCount,
    this.totalTaxMinor,
    this.currency,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `id` / `number` of the document.
  final String? documentId;

  /// `invoice` / `credit` / `receipt` / `estimate` / `expense` /
  /// `recurring`.
  final String? kind;

  /// `outstanding` / `paid` / `late` / `cancelled` / `draft` /
  /// `archived`.
  final String? state;

  /// `vat` / `gst` / `sales_tax` / `none`.
  final String? taxRegime;

  /// ISO 3166 — billing country.
  final String? country;

  /// Whether the supplied VAT number passed VIES validation
  /// (`true` enables B2B reverse charge).
  final bool? vatNumberValid;

  /// Whether the sale was classified as B2B (drives reverse charge).
  final bool? b2b;

  /// Number of evidence items attached (Quaderno requires two
  /// non-conflicting pieces of evidence for EU VAT MOSS / OSS).
  final int? evidenceCount;

  /// Total tax in minor units.
  final int? totalTaxMinor;

  /// ISO 4217.
  final String? currency;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class QuadernoCallResult<T> {
  /// Creates a call result.
  const QuadernoCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final QuadernoResult? result;
}

/// Wraps a Quaderno API call in a CLIENT span. [operation] is one of
/// `invoices.list`, `invoices.create`, `invoices.update`,
/// `invoices.deliver`, `invoices.pdf`, `credits.list`,
/// `credits.create`, `receipts.list`, `receipts.create`,
/// `estimates.list`, `expenses.list`, `recurring.list`,
/// `contacts.list`, `contacts.create`, `taxes.calculate`,
/// `taxes.validate_vat`, `evidences.list`, `webhooks.list`.
Future<T> tracedQuaderno<T>({
  required String operation,
  required Future<QuadernoCallResult<T>> Function() invoke,
}) async {
  if (quadernoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'quaderno',
    'rpc.method': operation,
    'quaderno.operation': operation,
  };

  final span = _tracer().startSpan(
    'quaderno $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'quaderno.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.documentId != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.document.id',
          r.result!.documentId!,
        ));
      }
      if (r.result!.kind != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.document.kind',
          r.result!.kind!,
        ));
      }
      if (r.result!.state != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.document.state',
          r.result!.state!,
        ));
        if (r.result!.state == 'cancelled') {
          span.setStatus(
            SpanStatusCode.Error,
            'Quaderno document cancelled',
          );
        }
      }
      if (r.result!.taxRegime != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.tax_regime',
          r.result!.taxRegime!,
        ));
      }
      if (r.result!.country != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.country',
          r.result!.country!,
        ));
      }
      if (r.result!.vatNumberValid != null) {
        extras.add(OTelAPI.attributeBool(
          'quaderno.vat_number.valid',
          r.result!.vatNumberValid!,
        ));
      }
      if (r.result!.b2b != null) {
        extras.add(OTelAPI.attributeBool(
          'quaderno.b2b',
          r.result!.b2b!,
        ));
      }
      if (r.result!.evidenceCount != null) {
        extras.add(OTelAPI.attributeInt(
          'quaderno.evidence_count',
          r.result!.evidenceCount!,
        ));
      }
      if (r.result!.totalTaxMinor != null) {
        extras.add(OTelAPI.attributeInt(
          'quaderno.tax.total.minor',
          r.result!.totalTaxMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'quaderno.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Quaderno HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
