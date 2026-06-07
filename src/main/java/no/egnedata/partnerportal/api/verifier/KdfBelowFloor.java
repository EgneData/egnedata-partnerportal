package no.egnedata.partnerportal.api.verifier;

public class KdfBelowFloor extends RuntimeException {

    public KdfBelowFloor(String message) {
        super(message);
    }
}
