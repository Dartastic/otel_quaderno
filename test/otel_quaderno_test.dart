// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_quaderno/otel_quaderno.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_quaderno-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('invoices.create records VAT MOSS evidence + B2B', () async {
    await tracedQuaderno<String>(
      operation: 'invoices.create',
      invoke: () async => const QuadernoCallResult(
        value: 'ok',
        result: QuadernoResult(
          documentId: 'INV-0001',
          kind: 'invoice',
          state: 'paid',
          taxRegime: 'vat',
          country: 'FR',
          vatNumberValid: true,
          b2b: true,
          evidenceCount: 2,
          totalTaxMinor: 2000,
          currency: 'EUR',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('quaderno invoices.create')!);
    expect(a['quaderno.tax_regime'], 'vat');
    expect(a['quaderno.vat_number.valid'], true);
    expect(a['quaderno.b2b'], true);
    expect(a['quaderno.evidence_count'], 2);
  });

  test('cancelled sets span error', () async {
    await tracedQuaderno<String>(
      operation: 'invoices.update',
      invoke: () async => const QuadernoCallResult(
        value: 'ok',
        result: QuadernoResult(state: 'cancelled'),
      ),
    );
    expect(
      spans.findSpanByName('quaderno invoices.update')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutQuadernoInstrumentationAsync(() async {
      await tracedQuaderno<String>(
        operation: 'invoices.list',
        invoke: () async => const QuadernoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('quaderno '), isEmpty);
  });
}
