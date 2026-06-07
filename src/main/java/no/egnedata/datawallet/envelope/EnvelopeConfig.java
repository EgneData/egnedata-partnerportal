package no.egnedata.datawallet.envelope;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
public class EnvelopeConfig {

    @Bean
    public EnvelopeCodec envelopeCodec() {
        return new EnvelopeCodec();
    }

    @Bean
    @Profile("!cli")
    public EnvelopeVerifier envelopeVerifier(EnvelopeCodec codec, IssuerKeyResolver keyResolver) {
        return new EnvelopeVerifier(codec, keyResolver);
    }
}
