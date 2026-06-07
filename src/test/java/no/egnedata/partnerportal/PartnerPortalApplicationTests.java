package no.egnedata.partnerportal;

import no.egnedata.partnerportal.persistence.PostgresTestcontainer;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
@Import(PostgresTestcontainer.class)
class PartnerPortalApplicationTests {

    @Test
    void contextLoads() {
    }
}
