package no.egnedata.partnerportal;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = "no.egnedata")
@EnableScheduling
public class PartnerPortalApplication {

    public static void main(String[] args) {
        SpringApplication.run(PartnerPortalApplication.class, args);
    }
}
