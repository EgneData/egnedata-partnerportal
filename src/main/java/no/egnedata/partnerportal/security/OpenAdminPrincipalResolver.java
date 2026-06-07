package no.egnedata.partnerportal.security;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * Dev/e2e resolver: grants admin access to every caller when mTLS is disabled.
 * Active only when {@code partnerportal.security.admin-mtls=false}.
 */
@Component
@ConditionalOnProperty(name = "partnerportal.security.admin-mtls", havingValue = "false")
public class OpenAdminPrincipalResolver implements AdminPrincipalResolver {

    @Override
    public Optional<String> resolve(HttpServletRequest request) {
        return Optional.of("internal");
    }
}
