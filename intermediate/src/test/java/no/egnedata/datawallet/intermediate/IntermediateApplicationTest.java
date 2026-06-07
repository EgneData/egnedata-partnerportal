package no.egnedata.datawallet.intermediate;

import no.egnedata.datawallet.intermediate.attestation.Attestation;
import no.egnedata.datawallet.intermediate.attestation.AttestationConfig;
import no.egnedata.datawallet.intermediate.attestation.StubAttestation;
import no.egnedata.datawallet.intermediate.client.PartnerPortalAdminClient;
import no.egnedata.datawallet.intermediate.denylist.RevocationDenyList;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.ActiveProfiles;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
@Import(IntermediateApplicationTest.StubClientConfig.class)
class IntermediateApplicationTest {

    @TestConfiguration
    static class StubClientConfig {
        @Bean
        @Primary
        public PartnerPortalAdminClient stubAdminClient() {
            return new PartnerPortalAdminClient("http://localhost:19999") {
                @Override
                public List<RevokedIssuer> getRevokedIssuers() {
                    return Collections.emptyList();
                }
            };
        }
    }

    @Autowired
    private Attestation attestation;

    @Test
    void startsWithStubMode() {
        assertThat(attestation).isInstanceOf(StubAttestation.class);
    }
}
