package no.egnedata.partnerportal.security;

import no.egnedata.partnerportal.api.entry.FixtureIssuerKeyResolver;
import no.egnedata.partnerportal.persistence.PostgresTestcontainer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "it"})
@Import({PostgresTestcontainer.class, FixtureIssuerKeyResolver.class})
@TestPropertySource(properties = "partnerportal.web-origin=https://wallet.example.com")
class CorsIT {

    @Autowired private MockMvc mvc;

    @Test
    void preflightFromConfiguredOrigin_returnsCorsHeaders() throws Exception {
        mvc.perform(options("/v1/directory/root")
                        .header("Origin", "https://wallet.example.com")
                        .header("Access-Control-Request-Method", "GET")
                        .header("Access-Control-Request-Headers", "Authorization"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "https://wallet.example.com"))
                .andExpect(header().exists("Access-Control-Allow-Methods"));
    }

    @Test
    void preflightFromDifferentOrigin_returnsNoCorsHeaders() throws Exception {
        mvc.perform(options("/v1/directory/root")
                        .header("Origin", "https://evil.example.com")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }
}
