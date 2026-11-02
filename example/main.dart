// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_quaderno/otel_quaderno.dart';

/// Traces Quaderno calls with OpenTelemetry.
///
/// `otel_quaderno` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Quaderno call in
/// [tracedQuaderno]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'quaderno-example');

  // Wraps a Quaderno API call in a CLIENT span.
  final quadernoId = await tracedQuaderno<String>(
    operation: 'invoices.create',
    invoke: () async {
      // Make the Quaderno call here, then report what it returned.
      const id = 'quaderno_8f3a2c';
      return const QuadernoCallResult(
          value: id,
          result: QuadernoResult(
              itemCount: 3,
              documentId: 'number',
              kind: 'invoice',
              state: 'outstanding',
              taxRegime: 'vat',
              country: 'example',
              vatNumberValid: true,
              b2b: true,
              evidenceCount: 3,
              totalTaxMinor: 1,
              currency: 'usd',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedQuaderno invoices.create returned $quadernoId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutQuadernoInstrumentationAsync.
  await runWithoutQuadernoInstrumentationAsync(
    () => tracedQuaderno<String>(
      operation: 'invoices.create',
      invoke: () async {
        const id = 'quaderno_8f3a2c';
        return const QuadernoCallResult(
            value: id,
            result: QuadernoResult(
                itemCount: 3,
                documentId: 'number',
                kind: 'invoice',
                state: 'outstanding',
                taxRegime: 'vat',
                country: 'example',
                vatNumberValid: true,
                b2b: true,
                evidenceCount: 3,
                totalTaxMinor: 1,
                currency: 'usd',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
