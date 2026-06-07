package no.egnedata.partnerportal.security;

import java.util.UUID;

public record BearerClaims(UUID installUuid, String jktB64, long expMs) {}
