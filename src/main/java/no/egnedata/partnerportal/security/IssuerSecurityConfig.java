package no.egnedata.partnerportal.security;

import no.egnedata.datawallet.directory.DirectoryRecordCodec;
import no.egnedata.partnerportal.domain.DirectoryRecordRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.time.Clock;

@Configuration
public class IssuerSecurityConfig {

    @Value("${partnerportal.security.issuer-mtls:true}")
    private boolean issuerMtls;

    @Value("${partnerportal.security.issuer-bearer.enabled:false}")
    private boolean issuerBearerEnabled;

    @Value("${partnerportal.security.issuer-bearer.audience:urn:datawallet:server}")
    private String issuerBearerAudience;

    @PostConstruct
    void validateIssuerSecurityConfig() {
        if (issuerMtls && issuerBearerEnabled) {
            throw new IssuerSecurityConfigurationError(
                    "issuer-bearer.enabled=true requires issuer-mtls=false");
        }
    }

    @Bean
    @Order(1)
    @ConditionalOnProperty(name = "partnerportal.security.issuer-mtls", havingValue = "true", matchIfMissing = true)
    public SecurityFilterChain issuerMtlsFilterChain(HttpSecurity http) throws Exception {
        http
                .securityMatcher("/v1/entries/**", "/v1/issuers/**")
                .csrf(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .headers(headers -> headers.cacheControl(cache -> cache.disable()))
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
                )
                .x509(x509 -> x509.subjectPrincipalRegex("CN=(.*?)(?:,|$)"))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/v1/entries").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/v1/entries/**").authenticated()
                        .requestMatchers(HttpMethod.POST, "/v1/issuers/**").authenticated()
                        .anyRequest().denyAll()
                );
        return http.build();
    }

    @Bean
    @Order(1)
    @ConditionalOnExpression(
            "${partnerportal.security.issuer-mtls:true} == false "
            + "&& ${partnerportal.security.issuer-bearer.enabled:false} == true"
    )
    public SecurityFilterChain issuerBearerFilterChain(HttpSecurity http,
                                                       BearerIssuerPrincipalResolver bearerResolver) throws Exception {
        http
                .securityMatcher("/v1/entries/**", "/v1/issuers/**")
                .csrf(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .headers(headers -> headers.cacheControl(cache -> cache.disable()))
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
                )
                .addFilterBefore(new IssuerBearerAuthFilter(bearerResolver),
                        UsernamePasswordAuthenticationFilter.class)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/v1/entries").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/v1/entries/**").authenticated()
                        .requestMatchers(HttpMethod.POST, "/v1/issuers/**").authenticated()
                        .anyRequest().denyAll()
                );
        return http.build();
    }

    @Bean
    @ConditionalOnExpression(
            "${partnerportal.security.issuer-mtls:true} == false "
            + "&& ${partnerportal.security.issuer-bearer.enabled:false} == true"
    )
    public BearerJwtVerifier bearerJwtVerifier() {
        return new BearerJwtVerifier(Clock.systemUTC());
    }

    @Bean
    @ConditionalOnExpression(
            "${partnerportal.security.issuer-mtls:true} == false "
            + "&& ${partnerportal.security.issuer-bearer.enabled:false} == true"
    )
    public BearerIssuerPrincipalResolver bearerIssuerPrincipalResolver(
            DirectoryRecordRepository directoryRecordRepository,
            DirectoryRecordCodec codec,
            BearerJwtVerifier bearerJwtVerifier) {
        return new BearerIssuerPrincipalResolver(
                directoryRecordRepository, codec, bearerJwtVerifier, issuerBearerAudience);
    }

    public static class IssuerSecurityConfigurationError extends RuntimeException {
        public IssuerSecurityConfigurationError(String message) {
            super(message);
        }
    }
}
