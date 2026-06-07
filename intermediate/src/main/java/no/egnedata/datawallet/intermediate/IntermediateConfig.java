package no.egnedata.datawallet.intermediate;

import no.egnedata.datawallet.intermediate.cbor.IntermediateCborMapper;
import no.egnedata.datawallet.intermediate.client.PartnerPortalAdminClient;
import no.egnedata.datawallet.intermediate.signer.DirectoryRecordSigner;
import no.egnedata.datawallet.intermediate.signer.JwsSigner;
import no.egnedata.datawallet.intermediate.signer.Signer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;

@Configuration
public class IntermediateConfig {

    @Bean
    public PartnerPortalAdminClient dataWalletAdminClient(
            @Value("${datawallet.intermediate.server-url}") String serverUrl) {
        return new PartnerPortalAdminClient(serverUrl);
    }

    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }

    @Bean
    public IntermediateCborMapper intermediateCborMapper() {
        return new IntermediateCborMapper();
    }

    @Bean
    public DirectoryRecordSigner directoryRecordSigner(Signer signer, IntermediateCborMapper cbor, Clock clock) {
        return new DirectoryRecordSigner(signer, cbor, clock);
    }

    @Bean
    public JwsSigner jwsSigner(Signer signer, Clock clock,
                               @Value("${datawallet.intermediate.bearer.audience:urn:datawallet:server}") String audience) {
        return new JwsSigner(signer, clock, audience);
    }
}
