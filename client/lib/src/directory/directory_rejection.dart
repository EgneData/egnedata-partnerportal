/// Base class for all directory-record verification failures.
sealed class DirectoryRejection implements Exception {
  final String message;

  const DirectoryRejection(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The CBOR bytes could not be parsed or are not in canonical form.
final class MalformedCbor extends DirectoryRejection {
  final Object? cause;

  const MalformedCbor(super.message, [this.cause]);
}

/// The record version is not supported by this implementation.
final class UnsupportedVersion extends DirectoryRejection {
  UnsupportedVersion(int version)
      : super('Unsupported directory record version: $version');
}

/// The [record_type] field contains an unknown value.
final class InvalidRecordType extends DirectoryRejection {
  InvalidRecordType(String type) : super('Invalid record_type: $type');
}

/// The [key_use] field contains an unknown value.
final class InvalidKeyUse extends DirectoryRejection {
  InvalidKeyUse(String use) : super('Invalid key_use: $use');
}

/// The [status] field contains an unknown value.
final class InvalidStatus extends DirectoryRejection {
  InvalidStatus(String status) : super('Invalid status: $status');
}

/// The record is older than the maximum allowed age (7 days).
final class FreshnessExpired extends DirectoryRejection {
  const FreshnessExpired(super.message);
}

/// Fewer distinct valid root signatures than the threshold.
final class QuorumBelowThreshold extends DirectoryRejection {
  QuorumBelowThreshold(int valid, int threshold)
      : super('Quorum below threshold: $valid valid signatures, '
            '$threshold required');
}

/// A root signature did not verify.
final class SignatureInvalid extends DirectoryRejection {
  const SignatureInvalid(super.message);
}

/// A signature references a root key ID not present in the pinned root.
final class RootKeyNotFound extends DirectoryRejection {
  const RootKeyNotFound(super.message);
}

/// A root key's validity window does not cover [issued_at].
final class RootKeyExpired extends DirectoryRejection {
  const RootKeyExpired(super.message);
}

/// Exactly one of root_signatures / parent_signature must be present; neither is.
final class SignatureContainerMissing extends DirectoryRejection {
  const SignatureContainerMissing(super.message);
}

/// Both root_signatures and parent_signature are present (XOR violation).
final class SignatureContainerConflict extends DirectoryRejection {
  const SignatureContainerConflict(super.message);
}

/// The chain depth exceeds the maximum of 2 (root → intermediate → leaf).
final class ChainTooDeep extends DirectoryRejection {
  const ChainTooDeep(super.message);
}

/// The parent record referenced by parent_key_id could not be found.
final class ParentNotFound extends DirectoryRejection {
  const ParentNotFound(super.message);
}

/// The parent record is not of record_type 'intermediate'.
final class ParentNotIntermediate extends DirectoryRejection {
  const ParentNotIntermediate(super.message);
}

/// The parent record is not active or its validity window does not cover now.
final class ParentInactive extends DirectoryRejection {
  const ParentInactive(super.message);
}

/// The parent_signature did not verify against the parent's public key.
final class ParentSignatureInvalid extends DirectoryRejection {
  const ParentSignatureInvalid(super.message);
}
