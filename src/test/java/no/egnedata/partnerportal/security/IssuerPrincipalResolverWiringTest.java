package no.egnedata.partnerportal.security;

import no.egnedata.partnerportal.persistence.PostgresTestcontainer;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Import;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

class IssuerPrincipalResolverWiringTest {

    @Nested
    @SpringBootTest(properties = {
            "partnerportal.security.issuer-mtls=true",
            "partnerportal.security.admin-mtls=false"
    })
    @ActiveProfiles({"test", "it"})
    @Import(PostgresTestcontainer.class)
    class MtlsTrueDefaultBearer {

        @Autowired
        private ApplicationContext context;

        @Test
        void exactlyOneResolverIsX509() {
            var resolvers = context.getBeansOfType(IssuerPrincipalResolver.class);
            assertThat(resolvers).hasSize(1);
            assertThat(resolvers.values().iterator().next()).isInstanceOf(X509IssuerPrincipalResolver.class);
        }

        @Test
        void mtlsFilterChainIsPresent() {
            var chains = context.getBeansOfType(SecurityFilterChain.class);
            assertThat(chains).containsKey("issuerMtlsFilterChain");
            assertThat(chains).doesNotContainKey("issuerBearerFilterChain");
        }
    }

    @Nested
    @SpringBootTest(properties = {
            "partnerportal.security.issuer-mtls=false",
            "partnerportal.security.issuer-bearer.enabled=false",
            "partnerportal.security.admin-mtls=false"
    })
    @ActiveProfiles({"test", "it"})
    @Import(PostgresTestcontainer.class)
    class MtlsFalseBearerFalse {

        @Autowired
        private ApplicationContext context;

        @Test
        void exactlyOneResolverIsHeader() {
            var resolvers = context.getBeansOfType(IssuerPrincipalResolver.class);
            assertThat(resolvers).hasSize(1);
            assertThat(resolvers.values().iterator().next()).isInstanceOf(HeaderIssuerPrincipalResolver.class);
        }
    }

    @Nested
    @SpringBootTest(properties = {
            "partnerportal.security.issuer-mtls=false",
            "partnerportal.security.issuer-bearer.enabled=true",
            "partnerportal.security.issuer-bearer.audience=urn:datawallet:server",
            "partnerportal.security.admin-mtls=false"
    })
    @ActiveProfiles({"test", "it"})
    @Import(PostgresTestcontainer.class)
    class MtlsFalseBearerTrue {

        @Autowired
        private ApplicationContext context;

        @Test
        void exactlyOneResolverIsBearer() {
            var resolvers = context.getBeansOfType(IssuerPrincipalResolver.class);
            assertThat(resolvers).hasSize(1);
            assertThat(resolvers.values().iterator().next()).isInstanceOf(BearerIssuerPrincipalResolver.class);
        }

        @Test
        void bearerFilterChainIsPresent() {
            var chains = context.getBeansOfType(SecurityFilterChain.class);
            assertThat(chains).containsKey("issuerBearerFilterChain");
            assertThat(chains).doesNotContainKey("issuerMtlsFilterChain");
        }
    }

    @Nested
    class MtlsTrueBearerTrueFails {

        @Test
        void startupFails() {
            assertThat(org.junit.jupiter.api.Assertions.assertThrows(Exception.class, () -> {
                new org.springframework.boot.builder.SpringApplicationBuilder(
                        no.egnedata.partnerportal.PartnerPortalApplication.class)
                        .properties(
                                "partnerportal.security.issuer-mtls=true",
                                "partnerportal.security.issuer-bearer.enabled=true",
                                "partnerportal.security.issuer-bearer.audience=urn:datawallet:server",
                                "partnerportal.security.admin-mtls=false",
                                "spring.datasource.url=jdbc:tc:postgresql:16:///partnerportal",
                                "spring.datasource.username=test",
                                "spring.datasource.password=test",
                                "partnerportal.web-origin=https://web.example.com"
                        )
                        .profiles("test")
                        .run();
            })).hasStackTraceContaining("issuer-bearer.enabled=true requires issuer-mtls=false");
        }
    }
}
