package no.egnedata.partnerportal.api.verifier;

public class HandleReserved extends RuntimeException {

    public HandleReserved(String handle) {
        super("Handle is reserved: " + handle);
    }
}
