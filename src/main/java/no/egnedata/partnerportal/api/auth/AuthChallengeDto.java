package no.egnedata.partnerportal.api.auth;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record AuthChallengeDto(
        @NotNull @JsonProperty("verifier_id") UUID verifierId
) {}
